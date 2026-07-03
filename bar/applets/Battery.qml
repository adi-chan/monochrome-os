// modules/Battery.qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services as Services
import qs.panels.RightPanel
import qs.panels.WidgetPanel
import qs.panels.Power
import qs.panels.Launchers
import qs.panels.Notifications
import qs.panels.Media
import qs.panels.OSD

Item {
    id: root

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.open = !root.open
    }

    implicitHeight: 28
    implicitWidth: bg.implicitWidth

    property bool open: false

    property color normalFillColor: Services.Theme.isDark ? "#212721" : "#d0d0d0"
    property color lowFillColor: "#f44336"
    property color chargingFillColor: "#48ed7f"
    property color bgColor: Services.Theme.bgSolid
    property color textColor: Services.Theme.text

    property int batteryPercent: 100
    property string batteryStatus: "Unknown"
    property string lastStatus: "Unknown"

    property bool startupDone: false
    property real animatedPercent: 100.0

    onBatteryPercentChanged: {
        if (!startupDone) {
            animPercent.from = 100
            animPercent.to = batteryPercent
            animPercent.running = true
            startupDone = true
        } else {
            animatedPercent = batteryPercent
        }
    }

    onBatteryStatusChanged: {
        if (lastStatus !== batteryStatus) {
            icon.scale = 0.7
            iconPop.from = 0.7
            iconPop.to = 1.0
            iconPop.running = true
        }
        lastStatus = batteryStatus
    }

    NumberAnimation {
        id: animPercent
        target: root
        property: "animatedPercent"
        duration: 700
        easing.type: Easing.InOutQuad
    }

    NumberAnimation {
        id: iconPop
        target: icon
        property: "scale"
        duration: 180
        easing.type: Easing.OutBack
    }

    Timer {
        interval: 100
        running: true
        repeat: true

        onTriggered: {
            readerPercent.running = true
            readerStatus.running = true
        }
    }

    Process {
        id: readerPercent
        running: true
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity"]

        stdout: StdioCollector {
            onStreamFinished: {
                let pct = parseInt(this.text.trim())
                if (!isNaN(pct))
                    root.batteryPercent = pct
            }
        }
    }

    Process {
        id: readerStatus
        running: true
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/status"]

        stdout: StdioCollector {
            onStreamFinished: root.batteryStatus = this.text.trim()
        }
    }

    ClippingRectangle {
        id: bg
        anchors.centerIn: parent
        height: 28
        radius: height / 2
        color: bgColor

        width: contentRow.implicitWidth + 16
        implicitWidth: width

        // ONLY pill zooms
        scale: area.containsMouse ? 1.08 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            width: batteryStatus === "Charging" 
                   ? Math.max(0, parent.width * (animatedPercent / 100.0) - 15)
                   : parent.width * (animatedPercent / 100.0)

            Behavior on width {
                NumberAnimation {
                    duration: 450
                    easing.type: Easing.InOutQuad
                }
            }

            property color fillColor: batteryStatus === "Charging"
                   ? chargingFillColor
                   : (batteryPercent <= 20 ? lowFillColor : normalFillColor)

            Behavior on fillColor {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            // Solid bar
            Rectangle {
                anchors.fill: parent
                color: fill.fillColor
                radius: 0
            }

            // Liquid wave (renders on top of the solid bar to extend it seamlessly)
            Rectangle {
                visible: batteryStatus === "Charging"
                x: parent.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: 14 // Squircle shape
                color: fill.fillColor

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 3000 // Slowed down from 1100 to 3000
                    loops: Animation.Infinite
                    running: batteryStatus === "Charging"
                }
            }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                id: icon
                text: batteryStatus === "Charging" ? "󰚥" : ""
                font.pixelSize: 14
                font.family: "Adwaita Sans"
                font.weight: 600
                color: textColor
            }

            Text {
                text: batteryPercent + "%"
                font.pixelSize: 14
                font.family: "JetBrains Mono"
                font.weight: 600
                color: textColor
            }
        }

        BatteryMenu {
            id: menu
            open: root.open
            anchorItem: bg
            batteryPercent: root.batteryPercent
            batteryStatus: root.batteryStatus
            onRequestClose: root.open = false
        }
    }
}