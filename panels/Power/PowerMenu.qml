// modules/PowerMenu.qml
import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

PanelWindow {
    id: pop

    // controlled by Power.qml
    property bool open: false
    property Item anchorItem: null
    property int gap: 10
    signal requestClose()

    // Full screen overlay setup
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: Qt.rgba(0, 0, 0, 0.75) // Dark dimming backdrop

    // Fade in/out animation
    opacity: open ? 1.0 : 0.0
    visible: opacity > 0.001
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // Close on click outside
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: requestClose()
    }

    // Esc to close
    Item {
        anchors.fill: parent
        focus: open
        Keys.onEscapePressed: requestClose()
    }

    // ---------- icons ----------
    property url iconDir: Qt.resolvedUrl("../../assets/power_icons")
    property url lockIcon:     iconDir + "/lock.svg"
    property url sleepIcon:    iconDir + "/moon.svg"
    property url logoutIcon:   iconDir + "/log-out.svg"
    property url rebootIcon:   iconDir + "/refresh-cw.svg"
    property url shutdownIcon: iconDir + "/power.svg"

    // ---------- gifs ----------
    property url lockGif:     iconDir + "/lock.gif"
    property url sleepGif:    iconDir + "/sleep.gif"
    property url rebootGif:   iconDir + "/restart.gif"
    property url shutdownGif: iconDir + "/poweroff.gif"

    // ---------- commands ----------
    property var lockCommand: ["qs", "ipc", "call", "lockscreen", "lock"]
    property var sleepCommand:    ["systemctl", "suspend"]
    property var logoutCommand:   ["hyprctl", "dispatch", "exit"]
    property var rebootCommand:   ["systemctl", "reboot"]
    property var shutdownCommand: ["systemctl", "poweroff"]

    function run(proc) {
        proc.running = false
        proc.running = true
        requestClose()
    }

    Process { id: lockProc;     command: pop.lockCommand }
    Process { id: sleepProc;    command: pop.sleepCommand }
    Process { id: logoutProc;   command: pop.logoutCommand }
    Process { id: rebootProc;   command: pop.rebootCommand }
    Process { id: shutdownProc; command: pop.shutdownCommand }

    Row {
        id: containerRow
        anchors.centerIn: parent
        spacing: -24 // overlap for the skew

        ActionItem { icon: pop.lockIcon;     label: "Lock";     gif: pop.lockGif;     onTriggered: pop.run(lockProc) }
        ActionItem { icon: pop.sleepIcon;    label: "Sleep";    gif: pop.sleepGif;    onTriggered: pop.run(sleepProc) }
        ActionItem { icon: pop.logoutIcon;   label: "Logout";   isLogout: true;       onTriggered: pop.run(logoutProc) }
        ActionItem { icon: pop.rebootIcon;   label: "Restart";  gif: pop.rebootGif;   danger: true; onTriggered: pop.run(rebootProc) }
        ActionItem { icon: pop.shutdownIcon; label: "Shutdown"; gif: pop.shutdownGif; danger: true; onTriggered: pop.run(shutdownProc) }
    }

    component ActionItem : Item {
        id: it
        width: hovered ? 440 : 120
        height: 500
        z: hovered ? 10 : 1

        property url icon: ""
        property string label: ""
        property url gif: ""
        property bool danger: false
        property bool isLogout: false
        
        signal triggered()
        property bool hovered: false

        Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutExpo } }

        Rectangle {
            id: rect
            width: parent.width
            height: parent.height
            color: "#111"
            radius: 20
            clip: true

            border.width: it.hovered ? 2 : 1
            border.color: it.hovered ? (it.danger ? "#ff4444" : "#ffffff") : "#333"

            // Skew animation: slants when unhovered, straightens when hovered
            property real skew: it.hovered ? 0 : -0.22
            Behavior on skew { NumberAnimation { duration: 450; easing.type: Easing.OutExpo } }

            // Outer skew
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, rect.skew, 0, -rect.skew * rect.height / 2,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                )
            }

            // Inner counter-skew so the images remain upright
            Item {
                id: contentWrapper
                anchors.centerIn: parent
                // Ensure width covers the diagonal corners
                width: parent.width + Math.abs(rect.skew) * parent.height + 4
                height: parent.height

                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(
                        1, -rect.skew, 0, rect.skew * rect.height / 2,
                        0, 1, 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1
                    )
                }

                // GIF Background
                AnimatedImage {
                    anchors.fill: parent
                    source: it.gif
                    fillMode: Image.PreserveAspectCrop
                    visible: it.gif !== ""
                    playing: it.hovered
                }

                // Fallback for Logout
                Rectangle {
                    anchors.fill: parent
                    color: "#1a1a1a"
                    visible: it.isLogout
                    Text {
                        anchors.centerIn: parent
                        text: "didn't find a gif\nfor this"
                        color: "#555"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Dark tint
                Rectangle {
                    anchors.fill: parent
                    color: it.danger && it.hovered ? "#33ff0000" : "#000000"
                    opacity: it.hovered ? 0.3 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // Static Icon
                Image {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: it.hovered ? -20 : 0
                    width: 48
                    height: 48
                    source: it.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: it.hovered ? 0.0 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }

                // Label Text
                Text {
                    anchors.centerIn: parent
                    text: it.label
                    color: "white"
                    font.pixelSize: 32
                    font.bold: true
                    opacity: it.hovered ? 1.0 : 0.0
                    scale: it.hovered ? 1.0 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }
            }

            // Mouse interaction
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: it.hovered = true
                onExited: it.hovered = false
                onClicked: {
                    mouse.accepted = true
                    it.triggered()
                }
            }
        }
    }
}
