pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRunning: false
    property int totalSeconds: 0
    property real remainingSeconds: 0
    property real progress: totalSeconds > 0 ? (remainingSeconds / totalSeconds) : 0

    // Notification process
    Process {
        id: notifyProc
        running: false
    }

    Timer {
        id: tickTimer
        interval: 50 // 20 fps for smooth UI
        repeat: true
        running: root.isRunning
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds = Math.max(0, root.remainingSeconds - 0.050);
                if (root.remainingSeconds === 0) {
                    // Timer finished!
                    root.isRunning = false;
                    notifyProc.command = ["bash", "-c", "notify-send -u critical '⏱️ Timer Finished' 'Your timer has ended!' && paplay /usr/share/sounds/freedesktop/stereo/complete.oga"];
                    notifyProc.running = true;
                }
            }
        }
    }

    function startTimer(hrs, mins) {
        var secs = hrs * 3600 + mins * 60;
        if (secs > 0) {
            totalSeconds = secs;
            remainingSeconds = secs;
            isRunning = true;
        }
    }

    function stopTimer() {
        isRunning = false;
    }

    function resetTimer() {
        isRunning = false;
        remainingSeconds = totalSeconds;
    }

    function toggleTimer() {
        if (remainingSeconds > 0) {
            isRunning = !isRunning;
        }
    }
}
