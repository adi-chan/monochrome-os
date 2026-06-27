import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    implicitHeight: 60
    Layout.fillWidth: true

    signal menuRequested()
    property string fallbackTitle: "Bluetooth"

    readonly property bool isConnected: Services.Bluetooth.connected
    readonly property bool isPowered: Services.Bluetooth.powered

    // Direct bindings to Theme properties - simple on/off only
    readonly property color bgColor:       isPowered ? "#2a2a2a" : "#1a1a1a"
    readonly property color borderColor:   "#333333"
    readonly property color iconColor:     isPowered ? "#cdd6f4" : "#a6adc8"
    readonly property color titleColor:    isPowered ? "#cdd6f4" : "#a6adc8"
    readonly property color subtitleColor: isPowered ? "#bac2de" : "#7f849c"
    Component.onCompleted: {
        console.log("[Bluetooth] theme loaded")
    }

    function btIcon(powered, connected) {
        if (!powered) return "󰂲"     // off
        if (connected) return "󰂱"    // connected
        return "󰂯"                   // on (not connected)
    }

    function subtitleText() {
        if (!isPowered) return "Off"
        return isConnected ? "Connected" : "On"
    }

    // Toggle Bluetooth power
    Process {
        id: btPowerProc
        command: ["bash", "-lc", "bluetoothctl power " + (root.isPowered ? "off" : "on")]
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: bgColor
        border.width: 1
        border.color: borderColor

        property bool hovered: false
        property bool pressed: false
        scale: pressed ? 0.98 : (hovered ? 1.01 : 1.0)

        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: btIcon(isPowered, isConnected)
                color: iconColor
                font.pixelSize: 18
                font.family: "Hack Nerd Font"
                opacity: isPowered ? 1.0 : 0.85
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -3
                Layout.alignment: Qt.AlignVCenter

                Text {
                    Layout.fillWidth: true
                    text: isConnected ? Services.Bluetooth.deviceName : root.fallbackTitle
                    color: titleColor
                    font.pixelSize: 14
                    font.weight: 600
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: subtitleText()
                    color: subtitleColor
                    opacity: 0.9
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onPressed: card.pressed = true
            onReleased: card.pressed = false
            onClicked: {
                root.menuRequested()
            }
        }
    }
}