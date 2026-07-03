import QtQuick
import qs.services as Services
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Services.Theme.bg
        border.width: 1
        border.color: Services.Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Helper component for individual app buttons
            component AppButton : Rectangle {
                id: btn
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: mouse.containsMouse ? Services.Theme.highlight : "transparent"

                property string iconTxt: ""
                property string cmd: ""

                scale: mouse.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: parent.iconTxt
                    font.pixelSize: 18
                    color: Services.Theme.text
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Process {
                    id: launchProc
                    running: false
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        launchProc.running = false
                        launchProc.command = ["hyprctl", "dispatch", "exec", btn.cmd]
                        launchProc.running = true
                    }
                }

                property alias mouse: mouse
            }

            // --- The Apps ---

            AppButton {
                iconTxt: "" // Terminal
                cmd: "foot"
            }

            AppButton {
                iconTxt: "" // Browser
                cmd: "flatpak run app.zen_browser.zen"
            }

            AppButton {
                iconTxt: "" // Files
                cmd: "thunar"
            }

            AppButton {
                iconTxt: "󰙯" // Discord
                cmd: "discord"
            }
        }
    }
}
