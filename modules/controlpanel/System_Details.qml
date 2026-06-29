// qs/modules/FillerTile.qml
import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    property string icon: ""
    signal clicked()

    property string cpuUsage: "CPU --%"
    property string ramUsage: "RAM --%"

    Process {
        id: sysFetch
        command: ["bash", "-c", "echo CPU $(top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}')% RAM $(free | awk '/Mem/ {printf(\"%d\", $3/$2 * 100)}')%"]

        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim().split(" ")
                if (out.length >= 4) {
                    root.cpuUsage = "CPU " + out[1]
                    root.ramUsage = "RAM " + out[3]
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            sysFetch.running = false
            sysFetch.running = true
        }
    }

    Process {
    id: missionCenter
    command: ["io.missioncenter.MissionCenter"]
}

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: Services.Theme.bg
        border.width: 1
        border.color: Services.Theme.border

        property bool hovered: false
        property bool pressed: false

        scale: pressed ? 0.98 : (hovered ? 1.01 : 1.0)

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item {
            anchors.fill: parent
            anchors.margins: 12

            Rectangle {
                id: iconRect
                width: 36
                height: 36
                radius: 18
                color: Services.Theme.border
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.pixelSize: 16
                    color: Services.Theme.text
                }
            }

            Column {
                anchors.left: iconRect.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: root.cpuUsage
                    font.pixelSize: 14
                    font.weight: 600
                    color: Services.Theme.text
                }

                Text {
                    text: root.ramUsage
                    font.pixelSize: 14
                    font.weight: 600
                    color: Services.Theme.text
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: card.hovered = true
            onExited:  card.hovered = false
            onPressed: card.pressed = true
            onReleased: card.pressed = false

            onClicked: {
                missionCenter.running = false
                missionCenter.running = true
            }
        }
    }
}