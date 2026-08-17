// modules/DateTime.qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as Services

Rectangle {
    id: root
    height: 28
    radius: height / 2

    // direct colors instead of Theme
    color: Services.Theme.bgSolid          // background color
    border.width: 1
    border.color: Services.Theme.bgSolid   // border color
    antialiasing: true

    property bool isPlaying: Services.Mpris.playbackStatus === "Playing"
    implicitWidth: isPlaying ? 320 : layoutRow.implicitWidth + 24
    
    Behavior on implicitWidth { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }
    
    property var audioData: new Array(80).fill(0)
    property int audioTick: 0
    Process {
        id: cavaProc
        running: root.isPlaying
        command: ["cava", "-p", "/home/nick/.config/quickshell/cava.conf"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";")
                let newArr = new Array(80)
                for (let i = 0; i < 80; i++) {
                    newArr[i] = parseInt(parts[i]) || 0
                }
                root.audioData = newArr
                root.audioTick++
            }
        }
    }

    Canvas {
        id: eqCanvas
        anchors.fill: parent
        anchors.margins: -16
        visible: root.isPlaying
        z: -1
        
        Connections {
            target: root
            function onAudioTickChanged() {
                eqCanvas.requestPaint();
            }
        }
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var w = width - 32;
            var h = height - 32;
            var R = h / 2;
            
            function getPillPoint(t) {
                var w_straight = Math.max(0, w - 2 * R);
                var arc_len = Math.PI * R;
                var total_len = 2 * w_straight + 2 * arc_len;
                
                var d = t * total_len;
                
                if (d <= w_straight) {
                    return { x: R + d, y: 0, nx: 0, ny: -1 };
                }
                d -= w_straight;
                
                if (d <= arc_len) {
                    var angle = -Math.PI/2 + (d / arc_len) * Math.PI;
                    return { x: w - R + Math.cos(angle) * R, y: R + Math.sin(angle) * R, nx: Math.cos(angle), ny: Math.sin(angle) };
                }
                d -= arc_len;
                
                if (d <= w_straight) {
                    return { x: w - R - d, y: h, nx: 0, ny: 1 };
                }
                d -= w_straight;
                
                var angle = Math.PI/2 + (d / arc_len) * Math.PI;
                return { x: R + Math.cos(angle) * R, y: R + Math.sin(angle) * R, nx: Math.cos(angle), ny: Math.sin(angle) };
            }
            
            ctx.fillStyle = root.color;
            ctx.beginPath();
            
            var points = 250;
            for (var i = 0; i <= points; i++) {
                var t = i / points;
                var pt = getPillPoint(t);
                
                var fIndex = (pt.x / w) * 79;
                var idx1 = Math.floor(fIndex);
                var idx2 = Math.min(79, idx1 + 1);
                var frac = fIndex - idx1;
                var val = (root.audioData[idx1] || 0) * (1 - frac) + (root.audioData[idx2] || 0) * frac;
                
                var h_offset = (val / 100) * 12;
                
                var cx = 16 + pt.x + pt.nx * h_offset;
                var cy = 16 + pt.y + pt.ny * h_offset;
                
                if (i === 0) {
                    ctx.moveTo(cx, cy);
                } else {
                    ctx.lineTo(cx, cy);
                }
            }
            ctx.closePath();
            ctx.fill();
        }
    }

    property bool hovered: false
    property bool pressed: false
    property string currentTime: ""

    property var panelWin: null
    property bool hasPendingReminder: false

    onHoveredChanged: {
        if (panelWin) {
            panelWin.buttonHovered = root.hovered
        }
    }

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

        // 1) Date/Time Container
        Item {
            id: timeWrapper
            property bool active: Services.Mpris.playbackStatus !== "Playing"
            width: active ? timeContainer.implicitWidth : 0
            height: timeContainer.implicitHeight
            opacity: active ? 1.0 : 0.0
            visible: opacity > 0
            clip: true
            
            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }

            Row {
                id: timeContainer
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
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // 2) Mini Media Player Container
        Item {
            id: mediaWrapper
            property bool active: Services.Mpris.playbackStatus === "Playing"
            width: active ? mediaContainer.implicitWidth : 0
            height: mediaContainer.implicitHeight
            opacity: active ? 1.0 : 0.0
            visible: opacity > 0
            clip: true
            
            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }

            Row {
                id: mediaContainer
                spacing: 8
                
                Text {
                    text: ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Services.Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: viewport
                    width: Math.min(240, textA.implicitWidth)
                    height: 20
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter
                    
                    property bool needsMarquee: false
                    property int fadeW: 12
                    
                    Row {
                        id: marqueeRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 22
                        x: 0
                        
                        Text {
                            id: textA
                            text: Services.Mpris.albumTitle
                            color: Services.Theme.text
                            font.pixelSize: 13
                            font.family: "JetBrains Mono"
                            font.weight: 700
                            elide: Text.ElideNone
                        }
                        
                        Text {
                            id: textB
                            text: textA.text
                            color: Services.Theme.text
                            font.pixelSize: 13
                            font.family: "JetBrains Mono"
                            font.weight: 700
                            elide: Text.ElideNone
                            visible: viewport.needsMarquee
                        }
                    }
                    
                    Item {
                        z: 10
                        visible: viewport.needsMarquee
                        width: viewport.fadeW
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true
                        
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.color }
                                GradientStop { position: 1.0; color: Qt.alpha(root.color, 0.0) }
                            }
                        }
                    }
                    
                    Item {
                        z: 10
                        visible: viewport.needsMarquee
                        width: viewport.fadeW
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true
                        
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.alpha(root.color, 0.0) }
                                GradientStop { position: 1.0; color: root.color }
                            }
                        }
                    }
                    
                    Timer {
                        id: marqueeDelay
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            if (viewport.needsMarquee) marqueeAnim.start()
                        }
                    }
                    
                    function recompute(resetPosition) {
                        viewport.needsMarquee = textA.implicitWidth > 240
                        
                        marqueeAnim.stop()
                        marqueeDelay.stop()
                        
                        if (resetPosition || !viewport.needsMarquee) marqueeRow.x = 0
                        
                        if (viewport.needsMarquee) {
                            marqueeAnim.from = 0
                            marqueeAnim.to = -(textA.implicitWidth + marqueeRow.spacing)
                            marqueeDelay.start()
                        }
                    }
                    
                    onWidthChanged: recompute(false)
                    Component.onCompleted: recompute(true)
                    
                    Connections {
                        target: Services.Mpris
                        function onAlbumTitleChanged() { viewport.recompute(true) }
                    }
                    
                    NumberAnimation {
                        id: marqueeAnim
                        target: marqueeRow
                        property: "x"
                        from: 0
                        to: -(textA.implicitWidth + marqueeRow.spacing)
                        duration: Math.max(8000, textA.implicitWidth * 22)
                        loops: Animation.Infinite
                        easing.type: Easing.Linear
                        running: false
                    }
                }
            }
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
        anchors.topMargin: -10
        anchors.bottomMargin: -10
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            root.hovered = true
            if (!root.panelWin || !root.panelWin.isOpen) {
                root.togglePanel()
            }
            if (root.panelWin) {
                root.panelWin.buttonHovered = true
            }
        }
        onExited: {
            root.hovered = false
            root.pressed = false
            if (root.panelWin) {
                root.panelWin.buttonHovered = false
            }
        }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
    }
}