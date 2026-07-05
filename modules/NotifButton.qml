import QtQuick
import qs.services as Services
import Quickshell
import Quickshell.Io
import qs.modules

Rectangle {
    id: root
    height: 28
    width: 32
    radius: height / 2

    color: Services.Theme.bgSolid
    border.width: 1
    border.color: Services.Theme.bgSolid
    antialiasing: true

    property bool hovered: false
    property bool pressed: false
    property var panelWin: null
    
    // Notification tracking
    property int lastKnownCount: 0
    property bool hasUnread: Services.Notifications.unreadCount > 0

    onHasUnreadChanged: {
        if (hasUnread) jingleAnim.start()
    }

    scale: pressed ? 0.985 : (hovered ? 1.03 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
    }

    Item {
        anchors.fill: parent
        
        Text {
            id: bellIcon
            anchors.centerIn: parent
            color: Services.Theme.text
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            text: "󰂚"
            
            transformOrigin: Item.Top
            
            SequentialAnimation {
                id: jingleAnim
                NumberAnimation { target: bellIcon; property: "rotation"; from: 0; to: -25; duration: 100 }
                NumberAnimation { target: bellIcon; property: "rotation"; from: -25; to: 25; duration: 100 }
                NumberAnimation { target: bellIcon; property: "rotation"; from: 25; to: -25; duration: 100 }
                NumberAnimation { target: bellIcon; property: "rotation"; from: -25; to: 25; duration: 100 }
                NumberAnimation { target: bellIcon; property: "rotation"; from: 25; to: 0; duration: 100 }
            }
        }
        
        Rectangle {
            id: unreadDot
            width: 6
            height: 6
            radius: 3
            color: Services.Theme.isDark ? "#f38ba8" : "#d32f2f" // Pastel red
            anchors.top: bellIcon.top
            anchors.right: bellIcon.right
            anchors.topMargin: -2
            anchors.rightMargin: -4
            visible: root.hasUnread
        }
    }

    // Removed /tmp polling and Timer processes

    function ensurePanel() {
        if (panelWin) return true

        const cmp = Qt.createComponent(Qt.resolvedUrl("NotificationCenter.qml"))
        if (cmp.status !== Component.Ready) {
            console.log("NotificationCenter load failed:", cmp.errorString())
            return false
        }

        panelWin = cmp.createObject(null)
        if (!panelWin) {
            console.log("NotificationCenter createObject failed")
            return false
        }

        return true
    }

    function togglePanel() {
        if (!ensurePanel()) return
        
        // Mark as read
        Services.Notifications.clearUnread()
        
        panelWin.togglePanelAnimation()
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
