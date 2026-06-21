import QtQuick
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
        color: "#000000"
        border.width: 1
        border.color: "#3a3a3a"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Helper component for individual script buttons
            component ScriptButton : Rectangle {
                id: btn
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: mouse.containsMouse ? "#3a3a3a" : "transparent"

                property string iconTxt: ""
                property string cmd: ""

                scale: mouse.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: parent.iconTxt
                    font.pixelSize: 18
                    color: mouse.containsMouse ? "#ffffff" : "#cdd6f4"
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
            }

            // --- The Scripts ---

            ScriptButton {
                iconTxt: "" // Screenshot
                cmd: "fish /home/nick/.config/hypr/scripts/snipshot.fish"
            }

            ScriptButton {
                iconTxt: "" // Record
                cmd: "fish /home/nick/.config/hypr/scripts/sniprec.fish"
            }

            ScriptButton {
                iconTxt: "" // OCR
                cmd: "fish /home/nick/.config/hypr/scripts/snipocr.fish"
            }

            ScriptButton {
                iconTxt: "" // Annotate
                cmd: "fish /home/nick/.config/hypr/scripts/annotate.fish"
            }

            ScriptButton {
                iconTxt: "" // Reload
                cmd: "fish /home/nick/.config/hypr/scripts/reload.fish"
            }
        }
    }
}
