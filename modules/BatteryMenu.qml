import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland


PopupWindow {
    id: pop

    property bool open: false
    property Item anchorItem: null
    property int batteryPercent: 0
    property string batteryStatus: ""

    signal requestClose()

    Timer {
        id: hideTimer
        interval: 800
    }

    onVisibleChanged: {
        if (!visible && pop.open) requestClose()
    }

    HoverHandler {
        id: rootHover
    }

    property bool buttonHovered: false
    property bool contentHovered: rootHover.hovered
    property bool shouldBeOpen: buttonHovered || contentHovered
    
    onShouldBeOpenChanged: {
        if (!shouldBeOpen) {
            closeTimer.restart()
        } else {
            closeTimer.stop()
        }
    }
    
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: {
            if (pop.open) requestClose()
        }
    }

    onOpenChanged: {
        if (!open && anchorItem !== null) hideTimer.start()
        else hideTimer.stop()
    }

    visible: (open || hideTimer.running) && anchorItem !== null
    color: "transparent"

    implicitWidth: 255
    implicitHeight: 150

    anchor.item: anchorItem

    // Backdrop and focus grab removed for pure hover functionality

    Connections {
        target: pop.anchor
        function onAnchoring() {
            if (!pop.anchorItem) return
            pop.anchor.rect.x = Math.round(pop.anchorItem.width / 2 - pop.width / 2)
            pop.anchor.rect.y = pop.anchorItem.height + 8
            pop.anchor.rect.width = 1
            pop.anchor.rect.height = 1
        }
    }

    property string currentProfile: "balanced"

    Process {
        id: profileRead
        command: ["bash", "-c", "busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile | cut -d'\"' -f2"]
        stdout: StdioCollector {
            onStreamFinished: pop.currentProfile = text.trim()
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: pop.visible
        triggeredOnStart: true
        onTriggered: profileRead.running = true
    }

    Process { id: perfProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "performance"]; onExited: profileRead.running = true }
    Process { id: balProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "balanced"]; onExited: profileRead.running = true }
    Process { id: saverProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "power-saver"]; onExited: profileRead.running = true }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        radius: 16
        color: Services.Theme.bgSolid

        y: pop.open ? 0 : -60
        opacity: pop.open ? 1.0 : 0.0
        scale: pop.open ? 1.0 : 0.85
        transformOrigin: Item.Top

        transform: Rotation {
            origin.x: mainRect.width / 2
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: pop.open ? 0 : -35
            Behavior on angle {
                NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 }
            }
        }

        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.28
            shadowVerticalOffset: 5
            shadowBlur: 0.55
        }

        MouseArea {
            id: contentMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Row {
                width: parent.width

                Text {
                    text: batteryPercent + "% "
                    color: Services.Theme.text
                    font.pixelSize: 34
                    font.family: "JetBrains Mono"
                    font.weight: 700
                }

                Item { width: 1; height: 1; Layout.fillWidth: true }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: batteryStatus
                    color: Services.Theme.text
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Row {
                spacing: 10

                IconBtn {
                    icon: "󱐋"   // performance
                    active: pop.currentProfile === "performance"
                    onClicked: perfProc.running = true
                }

                IconBtn {
                    icon: ""   // balanced (libra scale)
                    active: pop.currentProfile === "balanced"
                    onClicked: balProc.running = true
                }

                IconBtn {
                    icon: "󰌪"   // power-saver (leaf)
                    active: pop.currentProfile === "power-saver"
                    onClicked: saverProc.running = true
                }
            }
        }
    }

    component IconBtn : Rectangle {
        id: btn

        property string icon: ""
        property bool active: false
        signal clicked()

        width: 64
        height: 44
        radius: 12

        color: active ? Services.Theme.text : (mouse.containsMouse ? Services.Theme.highlight : Services.Theme.bg)
        border.width: 0

        scale: mouse.pressed ? 0.92 : (mouse.containsMouse ? 1.05 : 1.0)

        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }

        Text {
            id: iconText
            anchors.centerIn: parent
            text: btn.icon
            color: btn.active ? Services.Theme.bgSolid : Services.Theme.text
            font.pixelSize: 22
            font.family: "Hack Nerd Font"
            font.bold: true
            scale: btn.active ? 1.25 : 1.0
            
            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutElastic; easing.amplitude: 1.5; easing.period: 0.6 } }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}