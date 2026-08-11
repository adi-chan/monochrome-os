import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 70

    property var lastRx: 0
    property var lastTx: 0
    property string downSpeed: "0 KB/s"
    property string upSpeed: "0 KB/s"

    Process {
        id: speedProc
        command: ["bash", "-c", "iface=$(ip route | awk '/default/ {print $5}' | head -n1); if [ -z \"$iface\" ]; then echo '0 0'; else awk -v i=\"$iface\" '$1~i {print $2 \" \" $10}' /proc/net/dev; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var vals = text.trim().split(" ");
                if (vals.length >= 2) {
                    var rx = parseInt(vals[0]);
                    var tx = parseInt(vals[1]);
                    
                    if (root.lastRx > 0) {
                        var rxDiff = (rx - root.lastRx) / 1024;
                        var txDiff = (tx - root.lastTx) / 1024;
                        
                        if (rxDiff >= 0 && txDiff >= 0) {
                            root.downSpeed = (rxDiff > 1024 ? (rxDiff/1024).toFixed(1) + " MB/s" : Math.round(rxDiff) + " KB/s");
                            root.upSpeed = (txDiff > 1024 ? (txDiff/1024).toFixed(1) + " MB/s" : Math.round(txDiff) + " KB/s");
                        }
                    }
                    root.lastRx = rx;
                    root.lastTx = tx;
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            speedProc.running = false
            speedProc.running = true
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Download Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Services.Theme.bgSolid
            border.width: 1
            border.color: Services.Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Qt.rgba(0.2, 0.8, 0.4, 0.15) // Green tint
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰇚" // Download icon
                        font.pixelSize: 18
                        color: "#2ecc71"
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Download"
                        font.pixelSize: 12
                        color: Services.Theme.subtext
                        font.family: "JetBrains Mono"
                    }
                    Text {
                        text: root.downSpeed
                        font.pixelSize: 16
                        font.weight: 700
                        color: Services.Theme.text
                        font.family: "JetBrains Mono"
                    }
                }
            }
        }

        // Upload Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Services.Theme.bgSolid
            border.width: 1
            border.color: Services.Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Qt.rgba(0.6, 0.4, 0.8, 0.15) // Purple tint
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰕒" // Upload icon
                        font.pixelSize: 18
                        color: "#9b59b6"
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Upload"
                        font.pixelSize: 12
                        color: Services.Theme.subtext
                        font.family: "JetBrains Mono"
                    }
                    Text {
                        text: root.upSpeed
                        font.pixelSize: 16
                        font.weight: 700
                        color: Services.Theme.text
                        font.family: "JetBrains Mono"
                    }
                }
            }
        }
    }
}
