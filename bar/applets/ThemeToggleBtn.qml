import QtQuick
import QtQuick.Layouts
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
    width: 28
    radius: height / 2
    color: Services.Theme.bgSolid
    antialiasing: true
    
    border.color: Services.Theme.border
    border.width: 1

    property bool hovered: false
    property bool pressed: false

    scale: pressed ? 0.96 : (hovered ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: Services.Theme.isDark ? "󰖨" : "󰖔" // Sun for dark (to switch to light) or Moon for light
        color: Services.Theme.text
        font.pixelSize: 14
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true
        onReleased: {
            root.pressed = false
            Services.Theme.toggleTheme()
        }
    }
}
