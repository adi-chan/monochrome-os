import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property bool connected: false
    property string deviceName: "No Device"
    property string deviceId: ""
    property int batteryPercent: -1
    property bool isCharging: false
    property bool loading: false

    function refresh() {
        if (kdeProc.running) return
        root.loading = true
        kdeProc.running = false
        kdeProc.running = true
    }

    function ringPhone() {
        if (!root.connected || !root.deviceId) return
        ringProc.command = ["kdeconnect-cli", "-d", root.deviceId, "--ring"]
        ringProc.running = false
        ringProc.running = true
    }

    function pingPhone() {
        if (!root.connected || !root.deviceId) return
        pingProc.command = ["kdeconnect-cli", "-d", root.deviceId, "--ping"]
        pingProc.running = false
        pingProc.running = true
    }

    function shareClipboard() {
        if (!root.connected || !root.deviceId) return
        clipProc.command = ["bash", "-c", "kdeconnect-cli -d '" + root.deviceId + "' --share-text \"$(wl-paste 2>/dev/null || echo '')\""]
        clipProc.running = false
        clipProc.running = true
    }

    function shareMedia() {
        if (!root.connected || !root.deviceId) return
        mediaProc.command = ["bash", "-c", "FILE=$(zenity --file-selection --title='Select Media for Phone' 2>/dev/null || kdialog --getopenfilename 2>/dev/null); if [ -n \"$FILE\" ]; then kdeconnect-cli -d '" + root.deviceId + "' --share \"$FILE\"; fi"]
        mediaProc.running = false
        mediaProc.running = true
    }

    Timer {
        interval: 10000 // Poll every 10 seconds for real-time battery status
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: ringProc
        running: false
    }

    Process {
        id: pingProc
        running: false
    }

    Process {
        id: clipProc
        running: false
    }

    Process {
        id: mediaProc
        running: false
    }

    Process {
        id: kdeProc
        command: ["bash", "-c", "DEVID=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n 1); if [ -z \"$DEVID\" ]; then DEVID=$(kdeconnect-cli -l --id-only 2>/dev/null | head -n 1); fi; if [ -n \"$DEVID\" ]; then DEVNAME=$(kdeconnect-cli -a --name-only 2>/dev/null | head -n 1); [ -z \"$DEVNAME\" ] && DEVNAME=$(kdeconnect-cli -l --name-only 2>/dev/null | head -n 1); CHARGE=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/\"$DEVID\"/battery org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $2}'); ISCHARGING=$(busctl --user get-property org.kde.kdeconnect /modules/kdeconnect/devices/\"$DEVID\"/battery org.kde.kdeconnect.device.battery isCharging 2>/dev/null | awk '{print $2}'); echo \"{\\\"connected\\\": true, \\\"name\\\": \\\"$DEVNAME\\\", \\\"id\\\": \\\"$DEVID\\\", \\\"charge\\\": ${CHARGE:--1}, \\\"isCharging\\\": \\\"$ISCHARGING\\\"}\"; else echo '{\"connected\": false}'; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    if (text.trim().length === 0) return
                    let data = JSON.parse(text)
                    if (data.connected && data.id) {
                        root.connected = true
                        root.deviceName = (data.name && data.name.trim().length > 0) ? data.name.trim() : "Connected Phone"
                        root.deviceId = data.id.trim()
                        root.batteryPercent = typeof data.charge === "number" ? data.charge : parseInt(data.charge || -1)
                        root.isCharging = (data.isCharging === "true" || data.isCharging === true)
                    } else {
                        root.connected = false
                        root.deviceName = "No Device Connected"
                        root.deviceId = ""
                        root.batteryPercent = -1
                        root.isCharging = false
                    }
                } catch (e) {
                    console.log("KDE Connect DBus JSON parse error:", e)
                }
            }
        }
    }
}
