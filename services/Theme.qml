pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isDark: true

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
    }
}
