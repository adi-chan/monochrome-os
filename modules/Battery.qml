// modules/Battery.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services as Services

Item {
    id: root

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (!root.open) {
                root.open = true
            }
            if (menu) {
                menu.buttonHovered = true
            }
        }
        onExited: {
            if (menu) {
                menu.buttonHovered = false
            }
        }
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

    // Power Profile tracking
    property string currentProfile: "balanced"
    Process {
        id: profileRead
        command: ["bash", "-c", "busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile | cut -d'\"' -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim()
                if (p !== "") root.currentProfile = p
            }
        }
    }
    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: profileRead.running = true
    }

    function getProfileIcon(profile, status) {
        if (status === "Charging") return "󰚥"
        if (profile === "performance") return ""
        if (profile === "power-saver") return "󰌪"
        return ""
    }

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
        interval: 1000
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
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100"]

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
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/status 2>/dev/null || cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Discharging"]

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
                    duration: 3000
                    loops: Animation.Infinite
                    running: batteryStatus === "Charging"
                }
            }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                id: icon
                text: root.getProfileIcon(root.currentProfile, root.batteryStatus)
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                font.weight: 600
                color: textColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: batteryPercent + "%"
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                font.weight: 600
                color: textColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignVCenter
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