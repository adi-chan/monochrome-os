// qs/modules/controlpanel/System_Details.qml
import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    property string cpuVal: "--%"
    property string cpuFreq: "-- MHz"
    property string ramVal: "--%"
    property string ramUsed: "--"
    property string tempVal: "--°C"

    Process {
        id: sysFetch
        command: ["bash", "-c", "echo CPU $(top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}')% FREQ $(awk '/cpu MHz/ {print int($4); exit}' /proc/cpuinfo) TEMP $(sensors | awk '/Package id 0:/ {print $4}' | tr -d '+') RAM $(free | awk '/Mem/ {printf(\"%d\", $3/$2 * 100)}')% USED $(free -m | awk '/Mem/ {printf(\"%.1f_GB_/_%.1f_GB\", $3/1024, $2/1024)}')"]

        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim().split(" ")
                if (out.length >= 10) {
                    root.cpuVal = out[1]
                    root.cpuFreq = out[3] + " MHz"
                    root.tempVal = out[5]
                    root.ramVal = out[7]
                    root.ramUsed = out[9].replace(/_/g, " ")
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

    ColumnLayout {
        id: layout
        width: parent.width
        spacing: 8

        // Large Stat Button Component
        component StatButton: Rectangle {
            id: sBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            radius: 12
            color: mouseArea.containsMouse ? Services.Theme.highlight : Services.Theme.bgSolid
            border.width: 1
            border.color: Services.Theme.border
            
            Behavior on color { ColorAnimation { duration: 150 } }
            scale: mouseArea.pressed ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

            property string iconTxt: ""
            property string titleTxt: ""
            property string mainVal: ""
            property string subVal: ""
            property color accentColor: Services.Theme.primary
            
            signal clicked()

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: Qt.rgba(sBtn.accentColor.r, sBtn.accentColor.g, sBtn.accentColor.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: sBtn.iconTxt
                        font.pixelSize: 18
                        color: sBtn.accentColor
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: sBtn.titleTxt
                    font.pixelSize: 15
                    font.weight: 700
                    color: Services.Theme.text
                    font.family: "JetBrains Mono"
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 0
                    
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: sBtn.mainVal
                        font.pixelSize: 20
                        font.weight: 700
                        color: Services.Theme.text
                        font.family: "JetBrains Mono"
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignRight
                        visible: sBtn.subVal !== ""
                        text: sBtn.subVal
                        font.pixelSize: 10
                        color: Services.Theme.subtext
                    }
                }
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sBtn.clicked()
            }
        }

        StatButton {
            iconTxt: ""
            titleTxt: "Processor"
            mainVal: root.cpuVal
            subVal: root.cpuFreq
            accentColor: "#3498db"
            onClicked: {
                missionCenter.running = false
                missionCenter.running = true
            }
        }

        StatButton {
            iconTxt: ""
            titleTxt: "Memory"
            mainVal: root.ramVal
            subVal: root.ramUsed
            accentColor: "#2ecc71"
            onClicked: {
                missionCenter.running = false
                missionCenter.running = true
            }
        }

        StatButton {
            iconTxt: ""
            titleTxt: "Temperature"
            mainVal: root.tempVal
            subVal: ""
            accentColor: "#e74c3c"
            onClicked: {
                missionCenter.running = false
                missionCenter.running = true
            }
        }
    }
}