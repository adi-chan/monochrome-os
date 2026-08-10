pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string ssid: ""
    property int signalStrength: 0 // 0–100 %
    property bool wifiEnabled: true

    readonly property bool connected: ssid.length > 0 && wifiEnabled

    function toggleWifi() {
        var cmd = wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
        toggleProc.command = ["bash", "-c", cmd]
        toggleProc.running = false
        toggleProc.running = true
        wifiEnabled = !wifiEnabled
    }

    Process { id: toggleProc }

    Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            radioProc.running = false
            radioProc.running = true
            connectedSsidProc.running = false
            connectedSsidProc.running = true
        }
    }

    Process {
        id: radioProc
        command: ["bash", "-c", "nmcli radio wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = (text.trim().toLowerCase() === "enabled")
            }
        }
    }
    
    Process {
        id: connectedSsidProc
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi | grep '^yes:'"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                if (output.length > 0) {
                    var parts = output.split(":")
                    if (parts.length >= 3) {
                        var s = parts[1]
                        var strength = parseInt(parts[2])
                        root.ssid = (s && s.length > 0) ? s : ""
                        root.signalStrength = isNaN(strength) ? 0 : strength
                    } else {
                        root.ssid = ""
                        root.signalStrength = 0
                    }
                } else {
                    root.ssid = ""
                    root.signalStrength = 0
                }
            }
        }
    }
}
