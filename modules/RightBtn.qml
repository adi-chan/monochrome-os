// modules/RightBtn.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services as Services

Rectangle {
    id: root
    height: 28
    radius: height / 2
    color: Services.Theme.bgSolid
    antialiasing: true
    implicitWidth: row.implicitWidth + 12

    property bool hovered: false
    property bool pressed: false
    property bool open: false

    // IMPORTANT:
    // Anchor the panel to the *cluster* (your RowLayout in Bar.qml), not the button.
    // This makes the popup align with the right side of the whole cluster (LeftBtn + PfpPanel),
    // which naturally "pushes it right" without offsets.
    property Item panelAnchorItem: (root.parent ? root.parent : root)

    scale: pressed ? 0.96 : (hovered ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    function wifiIcon(connected, strength) {
        if (!connected) return "󰤮"
        if (strength >= 75) return "󰤨"
        if (strength >= 50) return "󰤥"
        if (strength >= 25) return "󰤢"
        return "󰤟"
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        Text {
            text: wifiIcon(Services.Network.connected, Services.Network.signalStrength)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.weight: 600
            color: Services.Theme.text
            opacity: Services.Network.connected ? 1.0 : 0.75
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: Services.Bluetooth.powered ? (Services.Bluetooth.connected ? "󰂱" : "󰂯") : "󰂲"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: 600
                color: Services.Theme.text
                opacity: Services.Bluetooth.connected ? 1.0 : 0.75
            }

            Text {
                visible: Services.Bluetooth.connected && Services.Bluetooth.battery !== ""
                text: Services.Bluetooth.battery + "%"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: 600
                color: Services.Theme.text
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            root.hovered = true
            if (!panel || !panel.open) {
                root.open = true
                Qt.callLater(panel.updatePos)
            }
            if (panel) {
                panel.buttonHovered = true
            }
        }
        onExited: {
            root.hovered = false
            root.pressed = false
            if (panel) {
                panel.buttonHovered = false
            }
        }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
    }

    RightPanel {
        id: panel
        open: root.open
        anchorItem: root.panelAnchorItem
        onRequestClose: root.open = false
    }
}
