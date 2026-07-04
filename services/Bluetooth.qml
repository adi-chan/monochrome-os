pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool powered: false
    property bool connected: false
    property string deviceName: ""
    property string deviceMac: ""
    property string battery: ""
    function refresh() {
        poweredProc.running = false
        poweredProc.running = true

        connectedDevProc.running = false
        connectedDevProc.running = true
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Powered: yes/no
    Process {
        id: poweredProc
        command: ["bash", "-lc", "bluetoothctl show | awk -F': ' '/Powered/ {print $2; exit}'"]

        stdout: StdioCollector {
            onStreamFinished: {
                var v = text.trim().toLowerCase()
                root.powered = (v === "yes" || v === "true" || v === "on")
                if (!root.powered) {
                    root.connected = false
                    root.deviceName = ""
                }
            }
        }
    }

    Process {
        id: connectedDevProc
        command: ["bash", "-lc", "dev=$(bluetoothctl devices Connected | head -n1); if [ -z \"$dev\" ]; then echo \"\"; exit 0; fi; mac=$(echo \"$dev\" | awk '{print $2}'); name=$(echo \"$dev\" | cut -d' ' -f3-); batt=$(bluetoothctl info \"$mac\" | grep 'Battery Percentage' | awk -F'[(|)]' '{print $2}' | tr -d ' ' ); echo \"$mac|$batt|$name\""]

        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()

                if (!root.powered || line.length === 0) {
                    root.connected = false
                    root.deviceName = ""
                    root.deviceMac = ""
                    root.battery = ""
                    return
                }

                var parts = line.split("|")
                if (parts.length >= 3) {
                    root.deviceMac = parts[0]
                    root.battery = parts[1]
                    root.deviceName = parts.slice(2).join("|")
                    root.connected = root.deviceName.length > 0
                    return
                }

                // fallback
                root.connected = false
                root.deviceName = ""
                root.deviceMac = ""
                root.battery = ""
            }
        }
    }
}
