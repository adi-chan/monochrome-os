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

    ListModel { id: btDevicesModel }
    readonly property alias devicesModel: btDevicesModel

    function togglePower() {
        var cmd = powered ? "bluetoothctl power off" : "bluetoothctl power on"
        btActionProc.command = ["bash", "-c", cmd]
        btActionProc.running = false
        btActionProc.running = true
        powered = !powered
    }

    function connectDevice(mac, isConnected) {
        if (!mac) return
        var cmd = isConnected ? ("bluetoothctl disconnect " + mac) : ("bluetoothctl connect " + mac)
        btActionProc.command = ["bash", "-c", cmd]
        btActionProc.running = false
        btActionProc.running = true
    }

    Process { 
        id: btActionProc
        onExited: root.refresh() 
    }

    function refresh() {
        poweredProc.running = false
        poweredProc.running = true
        devicesListProc.running = false
        devicesListProc.running = true
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
                    root.deviceMac = ""
                    root.battery = ""
                } else {
                    connectedDevProc.running = false
                    connectedDevProc.running = true
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
                root.connected = false
                root.deviceName = ""
                root.deviceMac = ""
                root.battery = ""
            }
        }
    }

    // Paired/Discovered devices list
    Process {
        id: devicesListProc
        command: ["bash", "-lc",
            "bluetoothctl devices | awk '{print $2}' | while read mac; do " +
            "  info=$(bluetoothctl info $mac 2>/dev/null); " +
            "  name=$(echo \"$info\" | sed -n 's/^\\s*Name: //p' | head -n1); " +
            "  conn=$(echo \"$info\" | grep -q \"Connected: yes\" && echo yes || echo no); " +
            "  if [ -n \"$mac\" ]; then echo \"$mac\\t${name:-Device}\\t$conn\"; fi; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                btDevicesModel.clear()
                var lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0)
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t")
                    if (parts.length >= 3) {
                        btDevicesModel.append({
                            mac: parts[0],
                            name: parts[1],
                            connected: (parts[2] === "yes")
                        })
                    }
                }
            }
        }
    }
}
