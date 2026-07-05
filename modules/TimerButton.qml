import QtQuick
import Quickshell
import qs.services as Services

Rectangle {
    id: root
    visible: Services.TimerService.totalSeconds > 0
    height: 28
    width: height
    radius: height / 2

    color: Services.Theme.bgSolid
    border.width: 1
    border.color: Services.Theme.bgSolid
    antialiasing: true

    property bool hovered: false
    property bool pressed: false

    scale: pressed ? 0.95 : (hovered ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    property var timerPopupWin: null

    function ensureTimerPopup() {
        if (timerPopupWin) return true
        const cmp = Qt.createComponent(Qt.resolvedUrl("TimerPopup.qml"))
        if (cmp.status !== Component.Ready) {
            console.log("TimerPopup load failed:", cmp.errorString())
            return false
        }
        timerPopupWin = cmp.createObject(null)
        if (!timerPopupWin) return false
        return true
    }

    function toggleTimerPopup() {
        if (!ensureTimerPopup()) return
        timerPopupWin.toggle()
    }

    Connections {
        target: Services.TimerService
        function onProgressChanged() { pillCanvas.requestPaint() }
    }

    Canvas {
        id: pillCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            var cx = width / 2;
            var cy = height / 2;
            var r = width / 2 - 3;
            
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = 2;
            ctx.strokeStyle = Services.Theme.border;
            ctx.stroke();
            
            ctx.beginPath();
            var p = Services.TimerService.progress;
            if (p > 0.001) {
                ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + p * 2 * Math.PI);
                ctx.lineWidth = 2;
                ctx.strokeStyle = Services.Theme.text;
                ctx.stroke();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "󰔛" // stopwatch icon
        color: Services.TimerService.isRunning ? Services.Theme.text : Services.Theme.subtext
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: { root.hovered = false; root.pressed = false }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onClicked: root.toggleTimerPopup()
    }
}
