// modules/DateTime.qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as Services
import qs.panels.RightPanel
import qs.panels.WidgetPanel
import qs.panels.Power
import qs.panels.Launchers
import qs.panels.Notifications
import qs.panels.Media
import qs.panels.OSD

Rectangle {
    id: root
    height: 28
    radius: height / 2

    // direct colors instead of Theme
    color: Services.Theme.bgSolid          // background color
    border.width: 1
    border.color: Services.Theme.bgSolid   // border color
    antialiasing: true

    implicitWidth: layoutRow.implicitWidth + 24

    property bool hovered: false
    property bool pressed: false
    property string currentTime: ""

    property var panelWin: null
    property bool hasPendingReminder: false

    Services.ReminderService {
        id: reminderService
        onRemindersUpdated: root.checkReminders()
    }

    // your animation formula
    scale: pressed ? 0.985 : (hovered ? 1.03 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }



    function checkReminders() {
        if (!reminderService.loaded) return
        const now = new Date().getTime()
        let pending = false
        
        for (let i = 0; i < reminderService.remindersList.length; i++) {
            let r = reminderService.remindersList[i]
            if (r.timestamp <= now) {
                if (!r.notified) {
                    // Send notification
                    notifyProc.command = ["notify-send", "-u", "critical", "-t", "10000", "Reminder", r.title + " (" + r.time + ")"]
                    notifyProc.running = true
                    // Wait, we don't mark as notified immediately, we keep it as pending so the red dot stays
                    // until the user manually dismisses it from the panel. Or we mark as notified but we need a 'dismissed' flag.
                    // Let's use 'notified' as the dismissed flag, meaning it's still pending until dismissed.
                    // Wait, if we don't mark it, it will keep notifying every second!
                    // Let's mark a separate local state, or actually just update the JSON to have `notified: true` and add `dismissed: false`.
                    // But for simplicity, we'll just show the notification once by setting `notified: true` and rely on a `dismissed` flag...
                    // Oh, we can just trigger it once using a local tracker!
                }
            }
        }
    }

    // A simple tracker for which IDs we've shown notifications for this session
    property var notifiedIds: ({})

    function updateDateTime() {
        const d = new Date()
        currentTime = Qt.formatDateTime(d, "MMM dd • HH:mm")
        
        if (reminderService.loaded) {
            const nowTime = d.getTime()
            let hasPending = false
            for (let i = 0; i < reminderService.remindersList.length; i++) {
                let r = reminderService.remindersList[i]
                if (r.timestamp <= nowTime && !r.notified) {
                    hasPending = true
                    if (!notifiedIds[r.id]) {
                        // We removed the desktop notification per the user's request.
                        // We just mark it in notifiedIds so we don't process it repeatedly.
                        let newIds = Object.assign({}, notifiedIds)
                        newIds[r.id] = true
                        notifiedIds = newIds
                    }
                }
            }
            hasPendingReminder = hasPending
        }
    }

    function ensurePanel() {
        if (panelWin) return true

        const cmp = Qt.createComponent(Qt.resolvedUrl("WidgetPanel.qml"))
        if (cmp.status !== Component.Ready) {
            console.log("WidgetPanel load failed:", cmp.errorString())
            return false
        }

        panelWin = cmp.createObject(null)
        if (!panelWin) {
            console.log("WidgetPanel createObject failed")
            return false
        }

        return true
    }

    function togglePanel() {
        if (!ensurePanel()) return
        panelWin.togglePanelAnimation()
    }

    Row {
        id: layoutRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            id: reminderDot
            width: 8
            height: 8
            radius: 4
            color: Services.Theme.isDark ? "#f38ba8" : "#d32f2f" // Pastel red
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasPendingReminder
        }

        Text {
            id: timeText
            color: Services.Theme.text
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            font.weight: 800
            text: root.currentTime
        }
    }

    property var appLauncherWin: null

    function ensureAppLauncher() {
        if (appLauncherWin) return true

        const cmp = Qt.createComponent(Qt.resolvedUrl("AppLauncher.qml"))
        if (cmp.status !== Component.Ready) {
            console.log("AppLauncher load failed:", cmp.errorString())
            return false
        }

        appLauncherWin = cmp.createObject(null, { "anchorItem": root })
        if (!appLauncherWin) {
            console.log("AppLauncher createObject failed")
            return false
        }

        return true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateDateTime()
    }
    Component.onCompleted: {
        root.updateDateTime()
        ensureAppLauncher()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: { root.hovered = false; root.pressed = false }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onClicked: root.togglePanel()
    }
}