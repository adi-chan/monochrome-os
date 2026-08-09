import QtQuick
import qs.services as Services

Item {
    id: root
    width: 60
    height: 60

    property real targetValue: 0
    property real value: 0
    property color ringColor: Services.Theme.isDark ? "#f38ba8" : "#d32f2f"
    property string icon: ""
    property string subText: ""

    Behavior on value { 
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic } 
    }

    onTargetValueChanged: root.value = targetValue
    onValueChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var x = width / 2
            var y = height / 2
            var r = Math.min(width, height) / 2 - 4

            // Background ring
            ctx.beginPath()
            ctx.arc(x, y, r, 0, 2 * Math.PI)
            ctx.lineWidth = 6
            ctx.strokeStyle = Services.Theme.border
            ctx.stroke()

            // Foreground ring
            ctx.beginPath()
            var start = -Math.PI / 2
            var end = start + (Math.max(0.01, root.value) / 100) * 2 * Math.PI
            ctx.arc(x, y, r, start, end)
            ctx.lineWidth = 6
            ctx.lineCap = "round"
            ctx.strokeStyle = root.ringColor
            ctx.stroke()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            text: root.icon
            font.family: "Hack Nerd Font"
            font.pixelSize: 14
            color: Services.Theme.text
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: root.subText
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            font.weight: 600
            color: Services.Theme.subtext
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.subText !== ""
        }
    }
}
