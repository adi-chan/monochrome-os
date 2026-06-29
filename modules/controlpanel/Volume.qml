import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.services as Services

import "../../services" as ServicesUI   // <-- points to /services (adjust if needed)

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: 56

    // ---- colors ----
    property color textColor: Services.Theme.text
    property color colPrimary: Services.Theme.primary
    property color colSecondaryContainer: Services.Theme.secondaryContainer
    property color handleBorderColor: Services.Theme.border
    property int handleBorderWidth: 1

    // ---- slider geometry ----
    property real trackHeightDiff: 15
    property real handleGap: 6
    property real trackNearHandleRadius: 2
    property bool useAnim: true

    // ---- pipewire/service reads ----
    readonly property var speaker: Services.Volume.defaultSpeaker
    readonly property var audio: (speaker && speaker.audio) ? speaker.audio : null

    // UI state
    property int uiValue: 0
    property bool dragging: false
    property int pendingValue: 0

    // menu state
    property bool menuOpen: false
    property bool canOpenMenu: true

    Timer {
        id: reopenCooldown
        interval: 300
        repeat: false
        onTriggered: root.canOpenMenu = true
    }

    function clamp(n, lo, hi) { return Math.max(lo, Math.min(hi, n)) }
    function volToUi(v) { return clamp(Math.round(clamp(v, 0.0, 1.0) * 100), 0, 100) }
    function uiToVol(u) { return clamp(u, 0, 100) / 100.0 }

    function syncFromAudio() {
        if (dragging) return
        if (!audio) return
        uiValue = volToUi(audio.volume)
    }

    signal sidePanelRequested()

    function toggleAudioMenu() {
        if (!root.canOpenMenu) return
        root.sidePanelRequested()
        // we leave menuOpen toggle logic to the parent if needed, or toggle here
        root.menuOpen = !root.menuOpen
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.syncFromAudio()
    }

    Timer {
        id: dragReleaseTimer
        interval: 200
        repeat: false
        onTriggered: root.dragging = false
    }

    Timer {
        id: applyTimer
        interval: 50
        repeat: false
        onTriggered: {
            var v = root.uiToVol(root.pendingValue)

            setProc.command = ["bash", "-lc",
                "if command -v wpctl >/dev/null 2>&1; then " +
                "  wpctl set-volume @DEFAULT_AUDIO_SINK@ " + v.toFixed(2) + "; " +
                "elif command -v pactl >/dev/null 2>&1; then " +
                "  pactl set-sink-volume @DEFAULT_SINK@ " + root.pendingValue + "%; " +
                "fi"
            ]
            setProc.running = false
            setProc.running = true

            if (root.speaker) Services.Volume.setVolume(root.speaker, v)
        }
    }

    Process { id: setProc }

    ColumnLayout {
        anchors.fill: parent
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "  Volume"
                font.family: "Hack Nerd Font"
                font.pixelSize: 14
                color: root.textColor
                opacity: 0.95
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.uiValue + "%"
                font.pixelSize: 14
                color: root.textColor
                opacity: 0.95
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                id: deviceBtn
                width: 26
                height: 26
                radius: 8
                border.width: 1
                border.color: Services.Theme.bg
                Layout.alignment: Qt.AlignVCenter

                property bool hovered: false
                property bool pressed: false

                color: Services.Theme.bg
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: 16
                    color: Services.Theme.subtext
                    opacity: 0.95
                    rotation: root.menuOpen ? 90 : 0
                    transformOrigin: Item.Center
                    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: deviceBtn.hovered = true
                    onExited: deviceBtn.hovered = false
                    onPressed: deviceBtn.pressed = true
                    onReleased: deviceBtn.pressed = false
                    onClicked: root.toggleAudioMenu()
                }
            }
        }

        ServicesUI.StyledSlider {
            id: slider
            Layout.fillWidth: true
            implicitHeight: 35

            from: 0
            to: 100
            stepSize: 1
            snapMode: Slider.SnapAlways

            colPrimary: root.colPrimary
            colSecondaryContainer: root.colSecondaryContainer
            handleBorderColor: root.handleBorderColor
            handleBorderWidth: root.handleBorderWidth
            trackHeightDiff: root.trackHeightDiff
            handleGap: root.handleGap
            trackNearHandleRadius: root.trackNearHandleRadius
            useAnim: root.useAnim

            onUserMoved: (v) => {
                root.dragging = true
                root.uiValue = Math.round(v)
                root.pendingValue = root.uiValue
                applyTimer.restart()
            }

            onUserReleased: (v) => {
                root.uiValue = Math.round(v)
                root.pendingValue = root.uiValue
                applyTimer.restart()
                dragReleaseTimer.restart()
            }
        }

        Binding {
            target: slider
            property: "value"
            value: root.uiValue
            when: !root.dragging
        }
    }


}
