import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    clip: true

    property string title: Services.Mpris.albumTitle
    property string artist: Services.Mpris.albumArtist
    property string artUrl: Services.Mpris.artUrl
    
    // Fallback gradient if no art is available
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Services.Theme.bgSolid
        border.color: Services.Theme.border
        border.width: 1
        clip: true

        // Background blurred art
        Image {
            id: bgArt
            anchors.fill: parent
            source: root.artUrl !== "" ? root.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3
            visible: false
            asynchronous: true
        }

        MultiEffect {
            source: bgArt
            anchors.fill: bgArt
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            opacity: bgArt.source.toString() !== "" ? 0.3 : 0
        }

        // Dark overlay to ensure text readability
        Rectangle {
            anchors.fill: parent
            color: Services.Theme.bgSolid
            opacity: 0.5
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24

            // Left side: Album Art
            Rectangle {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                radius: 12
                color: Services.Theme.bg

                Image {
                    id: mainArt
                    anchors.fill: parent
                    source: root.artUrl !== "" ? root.artUrl : "file:///home/nick/.config/quickshell/assets/music_fallback.svg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: mainArt.width
                                height: mainArt.height
                                radius: 12
                            }
                        }
                        shadowEnabled: true
                        shadowOpacity: 0.5
                        shadowBlur: 15
                        shadowVerticalOffset: 5
                    }

                    SequentialAnimation {
                        id: breathAnim
                        running: Services.Mpris.playbackStatus === "Playing"
                        loops: Animation.Infinite
                        PropertyAnimation { target: mainArt; property: "scale"; from: 1.0; to: 1.05; duration: 2500; easing.type: Easing.InOutSine }
                        PropertyAnimation { target: mainArt; property: "scale"; from: 1.05; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
                    }
                    
                    Connections {
                        target: Services.Mpris
                        function onPlaybackStatusChanged() {
                            if (Services.Mpris.playbackStatus !== "Playing") {
                                resetScaleAnim.start()
                            }
                        }
                    }
                    
                    PropertyAnimation {
                        id: resetScaleAnim
                        target: mainArt
                        property: "scale"
                        to: 1.0
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                
                // Fallback icon if no art
                Text {
                    anchors.centerIn: parent
                    visible: root.artUrl === ""
                    text: ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 48
                    color: Services.Theme.subtext
                }
            }

            // Right side: Info and Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Item { Layout.fillHeight: true } // Spacer

                // Track Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        font.family: "JetBrains Mono"
                        font.pixelSize: 22
                        font.weight: 800
                        color: Services.Theme.text
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.artist
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        color: Services.Theme.subtext
                        elide: Text.ElideRight
                    }
                }

                // Progress Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Layout.topMargin: 12

                    Rectangle {
                        id: progressBarArea
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Services.Theme.border
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10 // larger hit area
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (Services.Mpris.lengthSec > 0) {
                                    // Calculate relative click position ignoring the expanded margins
                                    var relativeX = Math.max(0, Math.min(mouse.x - 10, progressBarArea.width));
                                    var newPos = (relativeX / progressBarArea.width) * Services.Mpris.lengthSec;
                                    seekProc.command = ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "position", newPos.toString()];
                                    seekProc.running = true;
                                }
                            }
                        }

                        Rectangle {
                            height: parent.height
                            radius: 3
                            color: Services.Theme.primary
                            width: Services.Mpris.lengthSec > 0 ? parent.width * (Services.Mpris.positionSec / Services.Mpris.lengthSec) : 0
                            
                            Behavior on width { NumberAnimation { duration: 1000 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Services.Mpris.formatTime(Services.Mpris.positionSec)
                            color: Services.Theme.subtext
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Services.Mpris.formatTime(Services.Mpris.lengthSec)
                            color: Services.Theme.subtext
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24
                    Layout.topMargin: 8

                    Process { id: prevProc; command: ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "previous"] }
                    Process { id: nextProc; command: ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "next"] }
                    Process { id: seekProc; }

                    // Previous Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: prevMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { anchors.centerIn: parent; text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; color: Services.Theme.text }
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { prevProc.running = false; prevProc.running = true } }
                    }

                    // Play/Pause Button
                    Rectangle {
                        width: 64; height: 64; radius: 32
                        color: playMouse.containsMouse ? Qt.darker(Services.Theme.primary, 1.1) : Services.Theme.primary
                        Text { 
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: Services.Mpris.playbackStatus === "Playing" ? 0 : 3
                            text: Services.Mpris.playbackStatus === "Playing" ? "󰏤" : "󰐊" 
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                            color: Services.Theme.bgSolid
                        }
                        MouseArea { 
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Services.Mpris.playPause()
                            scale: pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: nextMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { anchors.centerIn: parent; text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; color: Services.Theme.text }
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { nextProc.running = false; nextProc.running = true } }
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
            }
        }
    }
}
