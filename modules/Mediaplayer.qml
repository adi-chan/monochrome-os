import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    implicitHeight: 32
    implicitWidth: 260
    Layout.preferredWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter

    // direct colors (replaced theme)
    property color bg: Services.Theme.bgSolid
    property color text: Services.Theme.text
    property color btnBg: Services.Theme.bg
    property color borderColor: Services.Theme.border

    // whole-module button feedback
    property color cardHover: "#2f3042"
    property color cardPress: "#2a2b3a"

    readonly property var mpris: Services.Mpris
    readonly property string line: (mpris.albumArtist || "No Artist") + " - " + (mpris.albumTitle || "No Media")

    property bool isPlaying: false
    property bool needsMarquee: false
    property int fadeW: 12

    property bool detailsOpen: false
    property var onOpen: function() { detailsOpen = !detailsOpen }

    Process { id: playPauseProc; command: ["playerctl", "play-pause"] }
    Process { id: prevProc; command: ["playerctl", "previous"] }
    Process { id: nextProc; command: ["playerctl", "next"] }

    Process {
        id: statusProc
        command: ["bash", "-lc", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: StdioCollector {
            onStreamFinished: root.isPlaying = (text.trim() === "Playing")
        }
    }

    Timer {
        interval: 800
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = false
            statusProc.running = true
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        antialiasing: true
        transformOrigin: Item.Center

        scale: cardMouse.pressed ? 0.985 : (cardMouse.containsMouse ? 1.03 : 1.0)
        color: root.bg

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: cardMouse.containsMouse ? 0.35 : 0.0
            shadowBlur: 0.9
            shadowVerticalOffset: cardMouse.containsMouse ? 2 : 0
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 0
            onClicked: root.onOpen()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8
            z: 1

            Rectangle {
                id: controlPill
                Layout.preferredWidth: 86
                Layout.preferredHeight: 24
                radius: 12
                color: root.btnBg
                border.width: 1
                border.color: root.borderColor
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 0

                    // Prev
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            color: root.text
                            opacity: prevMouse.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                prevProc.running = false
                                prevProc.running = true
                            }
                        }
                    }

                    // Play/Pause
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "󰏤" : "󰐊"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                            color: root.text
                            opacity: 0.95
                            visible: !root.isPlaying || btnMouse.containsMouse
                        }

                        // Animated Equalizer inside the button
                        Row {
                            id: eqIcon
                            anchors.centerIn: parent
                            spacing: 2
                            visible: root.isPlaying && !btnMouse.containsMouse
                            height: 10
                            
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 3
                                    height: 4
                                    radius: 1
                                    color: root.text
                                    anchors.bottom: parent.bottom
                                    
                                    SequentialAnimation on height {
                                        running: root.isPlaying
                                        loops: Animation.Infinite
                                        
                                        NumberAnimation { 
                                            to: index === 0 ? 10 : (index === 1 ? 6 : 8)
                                            duration: 200 + (index * 50)
                                            easing.type: Easing.InOutQuad 
                                        }
                                        NumberAnimation { 
                                            to: 3
                                            duration: 250 + (index * 30)
                                            easing.type: Easing.InOutQuad 
                                        }
                                        NumberAnimation { 
                                            to: index === 0 ? 5 : (index === 1 ? 10 : 7)
                                            duration: 180 + (index * 40)
                                            easing.type: Easing.InOutQuad 
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                playPauseProc.running = false
                                playPauseProc.running = true
                                statusProc.running = false
                                statusProc.running = true
                            }
                        }
                    }

                    // Next
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            color: root.text
                            opacity: nextMouse.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                nextProc.running = false
                                nextProc.running = true
                            }
                        }
                    }
                }
            }

            Item {
                id: viewport
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 20
                clip: true

                Row {
                    id: marqueeRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22
                    x: 0

                    Text {
                        id: textA
                        text: root.line
                        color: root.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 750
                        elide: Text.ElideNone
                    }

                    Text {
                        id: textB
                        text: textA.text
                        color: root.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 750
                        elide: Text.ElideNone
                        visible: root.needsMarquee
                    }
                }

                Item {
                    z: 10
                    visible: root.needsMarquee
                    width: root.fadeW
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.height
                        height: parent.width
                        rotation: -90
                        transformOrigin: Item.Center
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: card.color }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                Item {
                    z: 10
                    visible: root.needsMarquee
                    width: root.fadeW
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.height
                        height: parent.width
                        rotation: -90
                        transformOrigin: Item.Center
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: card.color }
                        }
                    }
                }

                Timer {
                    id: marqueeDelay
                    interval: 1000
                    repeat: false
                    onTriggered: {
                        if (root.needsMarquee) marqueeAnim.start()
                    }
                }

                function recompute(resetPosition) {
                    const usable = Math.max(0, viewport.width - (root.fadeW * 2))
                    root.needsMarquee = textA.paintedWidth > usable

                    marqueeAnim.stop()
                    marqueeDelay.stop()

                    if (resetPosition || !root.needsMarquee) marqueeRow.x = 0

                    if (root.needsMarquee) {
                        marqueeAnim.from = 0
                        marqueeAnim.to = -(textA.paintedWidth + marqueeRow.spacing)
                        marqueeDelay.start()
                    }
                }

                onWidthChanged: recompute(false)
                Component.onCompleted: recompute(true)

                Connections {
                    target: root.mpris
                    function onAlbumArtistChanged() { viewport.recompute(true) }
                    function onAlbumTitleChanged()  { viewport.recompute(true) }
                }

                NumberAnimation {
                    id: marqueeAnim
                    target: marqueeRow
                    property: "x"
                    from: 0
                    to: -(textA.paintedWidth + marqueeRow.spacing)
                    duration: Math.max(12000, textA.paintedWidth * 22)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                    running: false
                }
            }
        }
    }

    MediaPopup {
        id: mediaPop
        open: root.detailsOpen
        anchorItem: root
        onRequestClose: root.detailsOpen = false
    }
}