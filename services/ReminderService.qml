import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string savePath: {
        const x = Quickshell.env("XDG_CONFIG_HOME")
        return ((x && x.length > 0) ? x : (Quickshell.env("HOME") + "/.config")) + "/quickshell/assets/reminders.json"
    }

    property var remindersList: []
    property bool loaded: false
    signal remindersUpdated()

    function load() {
        if (loadProc.running) return
        loadProc.running = true
    }

    function save() {
        let jsonStr = JSON.stringify(root.remindersList, null, 2)
        saveProc.running = false
        saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname '" + savePath + "')\" && echo '" + jsonStr.replace(/'/g, "'\\''") + "' > '" + savePath + "'"]
        saveProc.running = true
    }

    Process {
        id: saveProc
        running: false
    }

    function addReminder(year, month, day, timeStr, title) {
        // timeStr should be "HH:MM"
        const hm = timeStr.split(":")
        const hh = parseInt(hm[0]) || 0
        const mm = parseInt(hm[1]) || 0
        const d = new Date(year, month, day, hh, mm)
        remindersList.push({
            id: Math.random().toString(36).substring(7),
            title: title,
            date: Qt.formatDateTime(d, "dd/MM/yyyy"),
            time: timeStr,
            timestamp: d.getTime(),
            notified: false
        })
        remindersList.sort((a, b) => a.timestamp - b.timestamp)
        save()
        remindersUpdated()
        load() // ensure reactivity
    }

    function dismissReminder(id) {
        let changed = false
        for (let i = 0; i < remindersList.length; i++) {
            if (remindersList[i].id === id) {
                remindersList[i].notified = true
                changed = true
            }
        }
        if (changed) {
            save()
            remindersUpdated()
            load()
        }
    }

    function deleteReminder(id) {
        const len = remindersList.length
        remindersList = remindersList.filter(r => r.id !== id)
        if (remindersList.length !== len) {
            save()
            remindersUpdated()
            load()
        }
    }

    Process {
        id: loadProc
        running: false
        command: ["sh", "-c", "test -f '" + savePath + "' && cat '" + savePath + "' || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.remindersList = JSON.parse(this.text.trim())
                    root.loaded = true
                    root.remindersUpdated()
                } catch(e) {
                    console.log("Failed to parse reminders.json:", e)
                    root.remindersList = []
                }
            }
        }
    }



    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.load()
    }

    Component.onCompleted: load()
}
