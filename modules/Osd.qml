import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import qs.services as Services

PanelWindow {
    id: root

    anchors {
        bottom: true
    }

    margins {
        bottom: 36
    }

    color: "transparent"
    exclusiveZone: -1 // Overlay window, does not push workspace layout
    mask: Region {} // Ignore all pointer events (click-through)

    implicitWidth: 340
    implicitHeight: 50

    property bool active: false
    property string mode: "volume"
    property real progressValue: 0.5
    property string iconText: "󰕾"
    property string labelText: "50%"

    readonly property var speaker: Services.Volume.defaultSpeaker
    readonly property var audio: (speaker && speaker.audio) ? speaker.audio : null

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: root.active = false
    }

    function showOsd(type, val, icon, text) {
        root.mode = type
        root.progressValue = Math.max(0, Math.min(1, val))
        root.iconText = icon
        root.labelText = text
        root.active = true
        hideTimer.restart()
    }

    function showVolumeOsd() {
        if (!root.audio) return
        var vol = root.audio.volume
        var pct = Math.round(vol * 100)
        var icon = root.audio.muted ? "󰖁" : (pct === 0 ? "󰖁" : (pct < 33 ? "󰕿" : (pct < 66 ? "󰖀" : "󰕾")))
        root.showOsd("volume", vol, icon, pct + "%")
    }

    function showBrightnessOsd() {
        brightProc.running = false
        brightProc.running = true
    }

    Process {
        id: brightProc
        command: ["bash", "-c", "echo $(brightnessctl g) $(brightnessctl m)"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    var cur = parseInt(parts[0]) || 0
                    var max = parseInt(parts[1]) || 1
                    var ratio = Math.max(0, Math.min(1, cur / max))
                    var pct = Math.round(ratio * 100)
                    var icon = pct < 33 ? "󰃞" : (pct < 66 ? "󰃟" : "󰃠")
                    root.showOsd("brightness", ratio, icon, pct + "%")
                }
            }
        }
    }

    Process {
        id: triggerCheck
        command: ["bash", "-c", "if [ -f /tmp/qs_osd_vol ]; then rm -f /tmp/qs_osd_vol; echo vol; elif [ -f /tmp/qs_osd_bright ]; then rm -f /tmp/qs_osd_bright; echo bright; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t === "vol") {
                    root.showVolumeOsd()
                } else if (t === "bright") {
                    root.showBrightnessOsd()
                }
            }
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (!triggerCheck.running) triggerCheck.running = true
        }
    }

    // Animated Container
    Item {
        id: container
        anchors.fill: parent

        // Slide up from bottom & fade in
        transform: Translate {
            y: root.active ? 0 : 35
            Behavior on y {
                NumberAnimation {
                    duration: 320
                    easing.type: root.active ? Easing.OutExpo : Easing.OutCubic
                }
            }
        }

        opacity: root.active ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: Services.Theme.bgSolid
            border.color: Services.Theme.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                Text {
                    text: root.iconText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Services.Theme.text
                    Layout.alignment: Qt.AlignVCenter
                }

                // Progress Track
                Rectangle {
                    id: track
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Services.Theme.secondaryContainer

                    Rectangle {
                        id: fill
                        width: parent.width * root.progressValue
                        height: parent.height
                        radius: parent.radius
                        color: Services.Theme.isDark ? "#ffffff" : "#000000"

                        Behavior on width {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    text: root.labelText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.weight: 700
                    color: Services.Theme.text
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
