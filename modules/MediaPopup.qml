import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs.services as Services

PopupWindow {
    id: pop

    property bool open: false
    property Item anchorItem: null
    signal requestClose()
    readonly property var m: Services.Mpris

    color: "transparent"

    property int cardRadius: 16
    property color cardColor: Services.Theme.bgSolid
    property color textColor: Services.Theme.text
    property color subTextColor: Services.Theme.subtext
    property color accentColor: Services.Theme.primary
    property color btnBg: Services.Theme.bg
    property color borderColor: Services.Theme.border
    property color coverFallback: Services.Theme.border

    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 6

    property int contentW: 325
    property int contentH: 96

    width: contentW + shadowPad * 2
    height: contentH + shadowPad * 2

    property bool closing: false
    visible: (open && anchorItem !== null) || closing

    property real animY: 0
    property real animScale: 1
    property real animOpacity: 1

    function playOpenAnim() {
        closing = false
        animY = -14
        animScale = 0.975
        animOpacity = 0
        openAnim.restart()
    }

    function playCloseAnim() {
        if (closing) return
        closing = true
        requestClose()
        focusGrab.active = false
        openAnim.stop()
        closeAnim.restart()
    }

    onVisibleChanged: {
        if (visible && open) playOpenAnim()
    }

    onOpenChanged: {
        if (!open && visible && !closing) playCloseAnim()
    }

    LazyLoader {
        id: backdropLoader
        activeAsync: pop.open || pop.closing

        PanelWindow {
            id: backdrop
            color: "transparent"
            visible: true
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onPressed: pop.playCloseAnim()
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [ pop ]
        active: pop.visible && !pop.closing
        onCleared: pop.playCloseAnim()
    }

    ParallelAnimation {
        id: openAnim

        SequentialAnimation {
            NumberAnimation { target: pop; property: "animY"; from: -14; to: 3; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animY"; from: 3; to: 0; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        }

        SequentialAnimation {
            NumberAnimation { target: pop; property: "animScale"; from: 0.975; to: 1.03; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animScale"; from: 1.03; to: 1.0; duration: 190; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
        }

        NumberAnimation { target: pop; property: "animOpacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim

        SequentialAnimation {
            NumberAnimation { target: pop; property: "animY"; from: 0; to: 2; duration: 70; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animY"; from: 2; to: -10; duration: 140; easing.type: Easing.InCubic }
        }

        NumberAnimation { target: pop; property: "animScale"; from: 1.0; to: 0.98; duration: 170; easing.type: Easing.InCubic }
        NumberAnimation { target: pop; property: "animOpacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }

        onStopped: pop.closing = false
    }

    anchor.item: anchorItem
    Connections {
        target: pop.anchor
        function onAnchoring() {
            if (!pop.anchorItem) return
            pop.anchor.rect.x = Math.round(pop.anchorItem.width / 2 - pop.width / 2)
            pop.anchor.rect.y = Math.round(pop.anchorItem.height + 8 - pop.shadowPad)
            pop.anchor.rect.width = 1
            pop.anchor.rect.height = 1
        }
    }

    property bool isPlaying: false

    Process {
        id: statProc
        command: ["bash", "-lc", "playerctl status 2>/dev/null || echo Stopped"]
        stdout: StdioCollector { onStreamFinished: pop.isPlaying = (text.trim() === "Playing") }
    }

    Timer {
        interval: 900
        repeat: true
        running: pop.visible
        triggeredOnStart: true
        onTriggered: { statProc.running = false; statProc.running = true }
    }

    Process { id: prevProc; command: ["playerctl", "previous"] }
    Process { id: nextProc; command: ["playerctl", "next"] }
    Process { id: seekProc }

    property string loopMode: "None"
    Process { id: loopSetProc }

    Process {
        id: loopGetProc
        command: ["bash", "-lc", "playerctl loop 2>/dev/null || echo None"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                pop.loopMode = (v === "Track" || v === "Playlist" || v === "None") ? v : "None"
            }
        }
    }

    function cycleLoop() {
        const next = (loopMode === "None") ? "Playlist"
                   : (loopMode === "Playlist") ? "Track"
                   : "None"
        loopMode = next
        loopSetProc.command = ["playerctl", "loop", next]
        loopSetProc.running = false
        loopSetProc.running = true
        loopGetProc.running = false
        loopGetProc.running = true
    }

    Timer {
        interval: 1200
        repeat: true
        running: pop.visible
        triggeredOnStart: true
        onTriggered: { loopGetProc.running = false; loopGetProc.running = true }
    }

    property bool dragging: false
    property real dragFrac: 0.0

    property bool seekPending: false
    property real pendingSec: 0

    Timer {
        id: pendingTimer
        interval: 1500
        repeat: false
        onTriggered: pop.seekPending = false
    }

    function clamp01(x) { return Math.max(0, Math.min(1, x)) }

    function liveFrac() {
        if (m.lengthSec <= 0) return 0
        return clamp01(m.positionSec / m.lengthSec)
    }

    Connections {
        target: pop.m
        function onPositionSecChanged() {
            if (!pop.seekPending) return
            if (Math.abs(pop.m.positionSec - pop.pendingSec) <= 1.5) {
                pop.seekPending = false
                pendingTimer.stop()
            }
        }
    }

    function displayedFrac() {
        if (dragging) return dragFrac
        if (seekPending && m.lengthSec > 0) return clamp01(pendingSec / m.lengthSec)
        return liveFrac()
    }

    function seekToFrac(f) {
        if (m.lengthSec <= 0) return
        const sec = Math.max(0, Math.min(m.lengthSec, Math.round(f * m.lengthSec)))

        pendingSec = sec
        seekPending = true
        pendingTimer.restart()

        seekProc.command = ["playerctl", "position", String(sec)]
        seekProc.running = false
        seekProc.running = true
    }

    property bool titleNeedsMarquee: false
    property int titleFadeW: 12

    component TapArea : MouseArea {
        id: tap
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property Item targetItem
        property real hoverScale: 1.08
        property real pressScale: 0.92

        onPressedChanged: {
            if (!targetItem) return
            targetItem.scale = pressed ? pressScale : (containsMouse ? hoverScale : 1.0)
        }
        onContainsMouseChanged: {
            if (!targetItem || pressed) return
            targetItem.scale = containsMouse ? hoverScale : 1.0
        }
    }

    Item {
        id: animWrap
        anchors.fill: parent
        anchors.margins: pop.shadowPad

        y: pop.animY
        scale: pop.animScale
        opacity: pop.animOpacity
        transformOrigin: Item.Top

        Rectangle {
            id: card
            anchors.fill: parent
            radius: pop.cardRadius
            antialiasing: true
            color: pop.cardColor
            border.width: 0

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: pop.shadowOpacity
                shadowVerticalOffset: pop.shadowOffsetY
                shadowBlur: pop.shadowBlur
            }
        }

        Rectangle {
            id: clipper
            anchors.fill: parent
            radius: pop.cardRadius
            color: "transparent"
            clip: true
            antialiasing: true

            MouseArea {
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                propagateComposedEvents: false
                onPressed: mouse.accepted = true
                onClicked: mouse.accepted = true
            }

            RowLayout {
                z: 1
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Item {
                    implicitWidth: 75
                    implicitHeight: 75
                    Layout.alignment: Qt.AlignVCenter

                    ClippingRectangle {
                        anchors.centerIn: parent
                        width: 83
                        height: 83
                        radius: 10
                        antialiasing: true
                        layer.enabled: true
                        layer.smooth: true

                        Rectangle { anchors.fill: parent; color: coverFallback }

                        Image {
                            anchors.fill: parent
                            source: m.artUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            visible: (m.artUrl && m.artUrl.length > 0)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                        height: 18

                        Item {
                            id: titleViewport
                            anchors.left: parent.left
                            anchors.right: repeatBtn.left
                            anchors.rightMargin: 8
                            height: 18
                            clip: true

                            Row {
                                id: titleRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 22
                                x: 0

                                Text {
                                    id: titleA
                                    text: m.albumTitle || "No Media"
                                    color: textColor
                                    font.pixelSize: 15
                                    font.weight: 700
                                    font.family: "JetBrains Mono"
                                    elide: Text.ElideNone
                                }

                                Text {
                                    id: titleB
                                    text: titleA.text
                                    color: textColor
                                    font.pixelSize: 15
                                    font.weight: 700
                                    elide: Text.ElideNone
                                    font.family: "JetBrains Mono"
                                    visible: pop.titleNeedsMarquee
                                }
                            }

                            Item {
                                z: 10
                                visible: pop.titleNeedsMarquee
                                width: pop.titleFadeW
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                clip: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.height
                                    height: parent.width
                                    rotation: -90
                                    transformOrigin: Item.Center
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: pop.cardColor }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }

                            Item {
                                z: 10
                                visible: pop.titleNeedsMarquee
                                width: pop.titleFadeW
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                clip: true
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.height
                                    height: parent.width
                                    rotation: -90
                                    transformOrigin: Item.Center
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: pop.cardColor }
                                    }
                                }
                            }

                            Timer {
                                id: titleDelay
                                interval: 900
                                repeat: false
                                onTriggered: { if (pop.titleNeedsMarquee) titleAnim.start() }
                            }

                            function recompute(reset) {
                                const usable = Math.max(0, titleViewport.width - pop.titleFadeW * 2)
                                pop.titleNeedsMarquee = (titleA.paintedWidth > usable)

                                titleAnim.stop()
                                titleDelay.stop()

                                if (reset || !pop.titleNeedsMarquee) titleRow.x = 0
                                if (pop.titleNeedsMarquee) {
                                    titleAnim.from = 0
                                    titleAnim.to = -(titleA.paintedWidth + titleRow.spacing)
                                    titleDelay.start()
                                }
                            }

                            onWidthChanged: recompute(false)
                            Component.onCompleted: recompute(true)

                            Connections {
                                target: pop.m
                                function onAlbumTitleChanged() { titleViewport.recompute(true) }
                            }

                            NumberAnimation {
                                id: titleAnim
                                target: titleRow
                                property: "x"
                                from: 0
                                to: -(titleA.paintedWidth + titleRow.spacing)
                                duration: Math.max(11000, titleA.paintedWidth * 20)
                                loops: Animation.Infinite
                                easing.type: Easing.Linear
                                running: false
                            }
                        }

                        Rectangle {
                            id: repeatBtn
                            width: 24
                            height: 24
                            radius: 8
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            z: 2

                            color: repeatTap.pressed ? "#2a2b3a"
                                 : (repeatTap.containsMouse ? "#2f3042" : "transparent")

                            border.width: (pop.loopMode === "None") ? 0 : 1
                            border.color: borderColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            transformOrigin: Item.Center
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                font.family: "JetBrains Mono"
                                font.pixelSize: 15
                                text: (pop.loopMode === "Track") ? "󰑘" : "󰑖"
                                color: textColor
                                opacity: (pop.loopMode === "None") ? 0.45 : 0.95
                            }

                            TapArea {
                                id: repeatTap
                                anchors.fill: parent
                                targetItem: repeatBtn
                                onClicked: pop.cycleLoop()
                            }
                        }
                    }

                    Text {
                        text: (m.albumArtist || "No Artist")
                        color: subTextColor
                        opacity: 0.9
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        font.family: "JetBrains Mono"
                        Layout.fillWidth: true
                    }

                    Item {
                        id: bar
                        Layout.fillWidth: true
                        height: 12

                        readonly property int pad: 6
                        readonly property real f: pop.displayedFrac()
                        readonly property real usableW: Math.max(1, width - pad * 2)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: bar.pad
                            width: bar.usableW
                            height: 4
                            radius: 2
                            color: btnBg
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: bar.pad
                            width: Math.max(6, bar.usableW * bar.f)
                            height: 4
                            radius: 2
                            color: accentColor
                        }

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: textColor
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(
                                   bar.pad,
                                   Math.min(
                                       bar.pad + bar.usableW - width,
                                       bar.pad + bar.usableW * bar.f - width / 2
                                   )
                               )
                            opacity: (m.lengthSec > 0) ? 0.9 : 0.25
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: (m.lengthSec > 0)

                            function updateDrag(mx) { pop.dragFrac = pop.clamp01((mx - bar.pad) / bar.usableW) }

                            onPressed: { pop.dragging = true; updateDrag(mouse.x) }
                            onPositionChanged: { if (pop.dragging) updateDrag(mouse.x) }
                            onReleased: {
                                updateDrag(mouse.x)
                                pop.dragging = false
                                pop.seekToFrac(pop.dragFrac)
                            }
                            onCanceled: pop.dragging = false
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 18

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: m.formatTime(
                                    pop.dragging ? (pop.dragFrac * m.lengthSec)
                                                 : (pop.seekPending ? pop.pendingSec : m.positionSec)
                                )
                                color: subTextColor
                                opacity: 0.85
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                            }

                            Item { Layout.fillWidth: true }

                            RowLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 16

                                Item {
                                    width: 18; height: 18
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        id: prevIcon
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 16
                                        color: textColor
                                        opacity: 0.9
                                        transformOrigin: Item.Center
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }
                                    TapArea {
                                        anchors.fill: parent
                                        targetItem: prevIcon
                                        onClicked: { prevProc.running = false; prevProc.running = true }
                                    }
                                }

                                Item {
                                    width: 20; height: 18
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        id: playIcon
                                        anchors.centerIn: parent
                                        text: pop.isPlaying ? "󰏤" : "󰐊"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 18
                                        color: textColor
                                        opacity: 0.95
                                        transformOrigin: Item.Center
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }
                                    TapArea {
                                        anchors.fill: parent
                                        targetItem: playIcon
                                        onClicked: m.playPause()
                                    }
                                }

                                Item {
                                    width: 18; height: 18
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        id: nextIcon
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 16
                                        color: textColor
                                        opacity: 0.9
                                        transformOrigin: Item.Center
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }
                                    TapArea {
                                        anchors.fill: parent
                                        targetItem: nextIcon
                                        onClicked: { nextProc.running = false; nextProc.running = true }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: m.formatTime(m.lengthSec)
                                color: subTextColor
                                opacity: 0.85
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                            }
                        }
                    }
                }
            }
        }
    }
}