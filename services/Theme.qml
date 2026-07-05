pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isDark: true

    Process {
        id: loadProc
        command: ["bash", "-c", "cat ~/.cache/qs_theme_dark 2>/dev/null || echo true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isDark = (text.trim() === "true");
            }
        }
    }

    Process {
        id: saveProc
        running: false
    }

    // Define colors with bindings
    property color bg: isDark ? "#0c0c0c" : "#f5f5f5"
    property color bgSolid: isDark ? "#000000" : "#ffffff"
    property color text: isDark ? "#ffffff" : "#000000"
    property color subtext: isDark ? "#a6adc8" : "#555555"
    property color border: isDark ? "#2a2a2a" : "#e0e0e0"
    
    // Sliders / Interactive elements
    property color primary: isDark ? "#ffffff" : "#000000"
    property color secondaryContainer: isDark ? "#454559" : "#d0d0d0"
    property color highlight: isDark ? "#313244" : "#cccccc"
    
    // Functions to toggle
    function toggleTheme() {
        isDark = !isDark;
        saveProc.command = ["bash", "-c", "echo " + isDark + " > ~/.cache/qs_theme_dark"]
        saveProc.running = false
        saveProc.running = true
    }
}
