import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services as Services

PanelWindow {
    id: win

    property int activeTab: 0 // 0: SYSTEM METRICS, 1: USAGE & WASTED TIME ANALYTICS
    property int usagePeriod: 0 // 0: DAILY, 1: WEEKLY, 2: MONTHLY

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: Services.AmICookedService.isCookedOpen || opacityAnim.running || scaleAnim.running

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: Services.AmICookedService.isCookedOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Close on ESC key press or Super+I
    Item {
        focus: Services.AmICookedService.isCookedOpen
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_I) {
                Services.AmICookedService.isCookedOpen = false;
                event.accepted = true;
            }
        }
    }

    // Transparent overlay container so ONLY the popup modal shows (NO weird full-screen dimming background)
    Rectangle {
        id: bgOverlay
        anchors.fill: parent
        color: "transparent"
        opacity: Services.AmICookedService.isCookedOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { id: opacityAnim; duration: 180; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Services.AmICookedService.isCookedOpen = false
        }

        // Popup Modal Window with Smooth Scale & Fade Micro-Animations
        Rectangle {
            id: mainCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 1050)
            height: Math.min(parent.height - 40, 810)
            color: Services.Theme.bg
            border.color: Services.Theme.border
            border.width: 1
            radius: 8

            // Smooth open / close animation behavior
            scale: Services.AmICookedService.isCookedOpen ? 1.0 : 0.92
            opacity: Services.AmICookedService.isCookedOpen ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation { id: scaleAnim; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                // HEADER BAR
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "AM I COOKED?"
                            color: Services.Theme.text
                            font.pixelSize: 26
                            font.bold: true
                            font.letterSpacing: 2
                        }
                        Text {
                            text: "LAPTOP SYSTEM METRICS & TIME USAGE DASHBOARD"
                            color: Services.Theme.subtext
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // DYNAMIC COOKED SCORE BADGE
                    Rectangle {
                        color: Services.Theme.isDark ? "#141414" : "#e0e0e0"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitWidth: scoreRow.implicitWidth + 24
                        implicitHeight: scoreRow.implicitHeight + 12

                        RowLayout {
                            id: scoreRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: Services.AmICookedService.stats.cooked.score + "% SCORE"
                                color: Services.Theme.text
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: "•  " + Services.AmICookedService.stats.cooked.tier
                                color: Services.Theme.subtext
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }

                    // CLOSE BUTTON
                    Rectangle {
                        color: Services.Theme.isDark ? "#141414" : "#e0e0e0"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitWidth: 36
                        implicitHeight: 36

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: Services.Theme.text
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.AmICookedService.isCookedOpen = false
                        }
                    }
                }

                // TAB SELECTOR HEADER
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        color: win.activeTab === 0 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitWidth: 168
                        implicitHeight: 34

                        Text {
                            anchors.centerIn: parent
                            text: "SYSTEM METRICS"
                            color: win.activeTab === 0 ? Services.Theme.bg : Services.Theme.text
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activeTab = 0
                        }
                    }

                    Rectangle {
                        color: win.activeTab === 1 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitWidth: 200
                        implicitHeight: 34

                        Text {
                            anchors.centerIn: parent
                            text: "USAGE & TIME WASTED"
                            color: win.activeTab === 1 ? Services.Theme.bg : Services.Theme.text
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activeTab = 1
                        }
                    }

                    Rectangle {
                        color: win.activeTab === 2 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitWidth: 148
                        implicitHeight: 34

                        Text {
                            anchors.centerIn: parent
                            text: "LIFETIME STATS"
                            color: win.activeTab === 2 ? Services.Theme.bg : Services.Theme.text
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activeTab = 2
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "UPTIME: " + (Services.AmICookedService.stats.usage_analytics ? Services.AmICookedService.stats.usage_analytics.uptime_formatted : "0m")
                        color: Services.Theme.subtext
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                // MPD MUSIC PLAYER BANNER (If MPD Active)
                Rectangle {
                    Layout.fillWidth: true
                    visible: Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.active : false
                    color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                    border.color: Services.Theme.border
                    border.width: 1
                    radius: 6
                    implicitHeight: 46

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // State tag
                        Rectangle {
                            color: Services.Theme.isDark ? "#222222" : "#dddddd"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 4
                            implicitWidth: 64
                            implicitHeight: 22

                            Text {
                                anchors.centerIn: parent
                                text: Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.state : "MPD"
                                color: Services.Theme.text
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        // Track info
                        Text {
                            text: Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.full_title : ""
                            color: Services.Theme.text
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Progress & Duration
                        Text {
                            text: (Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.elapsed : "0:00") + " / " + (Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.duration : "0:00") + " (" + (Services.AmICookedService.stats.mpd ? Services.AmICookedService.stats.mpd.track_no : "") + ")"
                            color: Services.Theme.subtext
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // ==================== TAB 0: SYSTEM METRICS ====================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: win.activeTab === 0
                    spacing: 14

                    // DIAGNOSIS SUMMARY BANNER
                    Rectangle {
                        Layout.fillWidth: true
                        color: Services.Theme.isDark ? "#111111" : "#eaeaea"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6
                        implicitHeight: diagCol.implicitHeight + 18

                        ColumnLayout {
                            id: diagCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                Text { text: "DIAGNOSIS:"; color: Services.Theme.subtext; font.pixelSize: 11; font.bold: true }
                                Text { text: Services.AmICookedService.stats.cooked.summary; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                            }

                            RowLayout {
                                Text { text: "FOCUSED APP:"; color: Services.Theme.subtext; font.pixelSize: 11; font.bold: true }
                                Text { 
                                    text: (Services.AmICookedService.stats.active_window.class || "None") + " - " + (Services.AmICookedService.stats.active_window.title || "")
                                    color: Services.Theme.text
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 650
                                }
                            }
                        }
                    }

                    // SYSTEM METRICS GRID (2x2)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12

                        // CARD 1: CPU & THERMALS
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 110

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text { text: "CPU & THERMALS"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Services.AmICookedService.stats.cpu.temp + " C"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Services.Theme.isDark ? "#222222" : "#cccccc"
                                    radius: 4
                                    Rectangle {
                                        width: parent.width * (Math.min(100, Services.AmICookedService.stats.cpu.usage_percent) / 100.0)
                                        height: parent.height
                                        color: Services.Theme.text
                                        radius: 4
                                    }
                                }

                                RowLayout {
                                    Text { text: "USAGE: " + Services.AmICookedService.stats.cpu.usage_percent + "%"; color: Services.Theme.text; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "LOAD: " + Services.AmICookedService.stats.cpu.load1 + ", " + Services.AmICookedService.stats.cpu.load5; color: Services.Theme.subtext; font.pixelSize: 11 }
                                }
                            }
                        }

                        // CARD 2: MEMORY & SWAP
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 110

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text { text: "MEMORY (RAM & SWAP)"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Services.AmICookedService.stats.memory.used_gb + " / " + Services.AmICookedService.stats.memory.total_gb + " GB"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Services.Theme.isDark ? "#222222" : "#cccccc"
                                    radius: 4
                                    Rectangle {
                                        width: parent.width * (Math.min(100, Services.AmICookedService.stats.memory.ram_percent) / 100.0)
                                        height: parent.height
                                        color: Services.Theme.text
                                        radius: 4
                                    }
                                }

                                RowLayout {
                                    Text { text: "RAM: " + Services.AmICookedService.stats.memory.ram_percent + "%"; color: Services.Theme.text; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "SWAP: " + Services.AmICookedService.stats.memory.swap_used_gb + "GB (" + Services.AmICookedService.stats.memory.swap_percent + "%)"; color: Services.Theme.subtext; font.pixelSize: 11 }
                                }
                            }
                        }

                        // CARD 3: BATTERY & POWER
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 110

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text { text: "BATTERY & POWER"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Services.AmICookedService.stats.battery.capacity + "% (" + Services.AmICookedService.stats.battery.status + ")"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Services.Theme.isDark ? "#222222" : "#cccccc"
                                    radius: 4
                                    Rectangle {
                                        width: parent.width * (Math.min(100, Services.AmICookedService.stats.battery.capacity) / 100.0)
                                        height: parent.height
                                        color: Services.Theme.text
                                        radius: 4
                                    }
                                }

                                RowLayout {
                                    Text { text: "POWER DRAW: " + Services.AmICookedService.stats.battery.power_w + " W"; color: Services.Theme.text; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "BAT TEMP: " + Services.AmICookedService.stats.battery.temp + " C"; color: Services.Theme.subtext; font.pixelSize: 11 }
                                }
                            }
                        }

                        // CARD 4: DISK STORAGE
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 110

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text { text: "STORAGE (ROOT /)"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: Services.AmICookedService.stats.disk.root_used_gb + " / " + Services.AmICookedService.stats.disk.root_total_gb + " GB"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Services.Theme.isDark ? "#222222" : "#cccccc"
                                    radius: 4
                                    Rectangle {
                                        width: parent.width * (Math.min(100, Services.AmICookedService.stats.disk.root_percent) / 100.0)
                                        height: parent.height
                                        color: Services.Theme.text
                                        radius: 4
                                    }
                                }

                                RowLayout {
                                    Text { text: "USED: " + Services.AmICookedService.stats.disk.root_percent + "%"; color: Services.Theme.text; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "FREE: " + Services.AmICookedService.stats.disk.root_free_gb + " GB"; color: Services.Theme.subtext; font.pixelSize: 11 }
                                }
                            }
                        }
                    }

                    // TOP PROCESS HOGS SECTION
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Services.Theme.isDark ? "#111111" : "#eaeaea"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text { text: "TOP RESOURCE HOGS (PROCESSES)"; color: Services.Theme.text; font.pixelSize: 12; font.bold: true }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: Services.AmICookedService.stats.processes.top_cpu || []

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 32
                                    color: index % 2 === 0 ? (Services.Theme.isDark ? "#161616" : "#f4f4f4") : (Services.Theme.isDark ? "#121212" : "#e8e8e8")
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 12

                                        Text { text: modelData.pid; color: Services.Theme.subtext; font.pixelSize: 11; font.family: "Monospace"; Layout.preferredWidth: 60 }
                                        Text { text: modelData.name; color: Services.Theme.text; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 200; elide: Text.ElideRight }
                                        Text { text: "CPU: " + modelData.cpu + "%"; color: Services.Theme.text; font.pixelSize: 11; Layout.preferredWidth: 90 }
                                        Text { text: "MEM: " + modelData.mem + "%"; color: Services.Theme.subtext; font.pixelSize: 11; Layout.preferredWidth: 90 }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            color: Services.Theme.isDark ? "#222222" : "#cccccc"
                                            border.color: Services.Theme.border
                                            border.width: 1
                                            radius: 4
                                            implicitWidth: 54
                                            implicitHeight: 22

                                            Text {
                                                anchors.centerIn: parent
                                                text: "KILL"
                                                color: Services.Theme.text
                                                font.pixelSize: 10
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Services.AmICookedService.killProcess(modelData.pid)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 1: USAGE & TIME WASTED ANALYTICS ====================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: win.activeTab === 1
                    spacing: 14

                    // PERIOD SELECTOR BAR
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            color: win.usagePeriod === 0 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 4
                            implicitWidth: 100
                            implicitHeight: 30

                            Text {
                                anchors.centerIn: parent
                                text: "DAILY"
                                color: win.usagePeriod === 0 ? Services.Theme.bg : Services.Theme.text
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.usagePeriod = 0
                            }
                        }

                        Rectangle {
                            color: win.usagePeriod === 1 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 4
                            implicitWidth: 100
                            implicitHeight: 30

                            Text {
                                anchors.centerIn: parent
                                text: "WEEKLY"
                                color: win.usagePeriod === 1 ? Services.Theme.bg : Services.Theme.text
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.usagePeriod = 1
                            }
                        }

                        Rectangle {
                            color: win.usagePeriod === 2 ? Services.Theme.text : (Services.Theme.isDark ? "#141414" : "#e4e4e4")
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 4
                            implicitWidth: 100
                            implicitHeight: 30

                            Text {
                                anchors.centerIn: parent
                                text: "MONTHLY"
                                color: win.usagePeriod === 2 ? Services.Theme.bg : Services.Theme.text
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.usagePeriod = 2
                            }
                        }
                    }

                    // SUMMARY CARDS (TOTAL vs WASTED vs PRODUCTIVE)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // TOTAL TIME
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 70

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "TOTAL TRACKED TIME"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        if (!ua) return "0m";
                                        var periodData = win.usagePeriod === 0 ? ua.daily : (win.usagePeriod === 1 ? ua.weekly : ua.monthly);
                                        return periodData ? periodData.total_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                        }

                        // TIME WASTED
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#1c1414" : "#fde8e8"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 70

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "TIME WASTED (ENTERTAINMENT)"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        if (!ua) return "0m";
                                        var periodData = win.usagePeriod === 0 ? ua.daily : (win.usagePeriod === 1 ? ua.weekly : ua.monthly);
                                        return periodData ? periodData.wasted_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                        }

                        // PRODUCTIVE TIME
                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#141c14" : "#e8fde8"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 70

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "PRODUCTIVE / CODE TIME"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        if (!ua) return "0m";
                                        var periodData = win.usagePeriod === 0 ? ua.daily : (win.usagePeriod === 1 ? ua.weekly : ua.monthly);
                                        return periodData ? periodData.productive_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // APPLICATION BREAKDOWN LIST
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Services.Theme.isDark ? "#111111" : "#eaeaea"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text { 
                                text: "TOP APPLICATIONS USED (" + (win.usagePeriod === 0 ? "DAILY" : (win.usagePeriod === 1 ? "WEEKLY" : "MONTHLY")) + ")"
                                color: Services.Theme.text
                                font.pixelSize: 12
                                font.bold: true 
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: {
                                    var ua = Services.AmICookedService.stats.usage_analytics;
                                    if (!ua) return [];
                                    var periodData = win.usagePeriod === 0 ? ua.daily : (win.usagePeriod === 1 ? ua.weekly : ua.monthly);
                                    return periodData ? periodData.top_apps : [];
                                }

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 36
                                    color: index % 2 === 0 ? (Services.Theme.isDark ? "#161616" : "#f4f4f4") : (Services.Theme.isDark ? "#121212" : "#e8e8e8")
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Text { text: "#" + (index + 1); color: Services.Theme.subtext; font.pixelSize: 11; font.family: "Monospace"; Layout.preferredWidth: 30 }
                                        Text { text: modelData.name; color: Services.Theme.text; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 240; elide: Text.ElideRight }

                                        // Category Tag Badge
                                        Rectangle {
                                            color: modelData.is_wasted 
                                                ? (Services.Theme.isDark ? "#381a1a" : "#f5d8d8") 
                                                : (modelData.is_productive 
                                                    ? (Services.Theme.isDark ? "#1a381a" : "#d8f5d8") 
                                                    : (Services.Theme.isDark ? "#222222" : "#e0e0e0"))
                                            border.color: Services.Theme.border
                                            border.width: 1
                                            radius: 4
                                            implicitWidth: 110
                                            implicitHeight: 22

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.is_wasted ? "ENTERTAINMENT" : (modelData.is_productive ? "PRODUCTIVE" : "GENERAL")
                                                color: modelData.is_wasted
                                                    ? (Services.Theme.isDark ? "#ff8080" : "#7a1515")
                                                    : (modelData.is_productive 
                                                        ? (Services.Theme.isDark ? "#80ff80" : "#0f520f")
                                                        : Services.Theme.text)
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text { text: modelData.formatted; color: Services.Theme.text; font.pixelSize: 11; font.bold: true }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 2: LIFETIME STATS ====================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: win.activeTab === 2
                    spacing: 14

                    // LIFETIME HEADER SUMMARY CARDS
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#121212" : "#f0f0f0"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 76

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "ALL TIME TRACKED"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        return ua && ua.lifetime ? ua.lifetime.total_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                Text {
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        return (ua ? ua.days_tracked : 0) + " DAYS TRACKED";
                                    }
                                    color: Services.Theme.subtext
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#1c1414" : "#fde8e8"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 76

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "LIFETIME WASTED"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        return ua && ua.lifetime ? ua.lifetime.wasted_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            color: Services.Theme.isDark ? "#141c14" : "#e8fde8"
                            border.color: Services.Theme.border
                            border.width: 1
                            radius: 6
                            implicitHeight: 76

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { text: "LIFETIME PRODUCTIVE"; color: Services.Theme.subtext; font.pixelSize: 10; font.bold: true }
                                Text { 
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        return ua && ua.lifetime ? ua.lifetime.productive_formatted : "0m";
                                    }
                                    color: Services.Theme.text
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // LIFETIME APP BREAKDOWN
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Services.Theme.isDark ? "#111111" : "#eaeaea"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 6

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Text { 
                                    text: "ALL-TIME TOP APPLICATIONS"
                                    color: Services.Theme.text
                                    font.pixelSize: 12
                                    font.bold: true 
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: {
                                        var ua = Services.AmICookedService.stats.usage_analytics;
                                        return "TRACKING SINCE FIRST RUN  |  " + (ua ? ua.days_tracked : 0) + " DAYS";
                                    }
                                    color: Services.Theme.subtext
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: {
                                    var ua = Services.AmICookedService.stats.usage_analytics;
                                    if (!ua || !ua.lifetime) return [];
                                    return ua.lifetime.top_apps;
                                }

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 38
                                    color: index % 2 === 0 ? (Services.Theme.isDark ? "#161616" : "#f4f4f4") : (Services.Theme.isDark ? "#121212" : "#e8e8e8")
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 12

                                        Text { text: "#" + (index + 1); color: Services.Theme.subtext; font.pixelSize: 11; font.family: "Monospace"; Layout.preferredWidth: 30 }
                                        Text { text: modelData.name; color: Services.Theme.text; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 260; elide: Text.ElideRight }

                                        Rectangle {
                                            color: modelData.is_wasted 
                                                ? (Services.Theme.isDark ? "#381a1a" : "#f5d8d8") 
                                                : (modelData.is_productive 
                                                    ? (Services.Theme.isDark ? "#1a381a" : "#d8f5d8") 
                                                    : (Services.Theme.isDark ? "#222222" : "#e0e0e0"))
                                            border.color: Services.Theme.border
                                            border.width: 1
                                            radius: 4
                                            implicitWidth: 110
                                            implicitHeight: 22

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.is_wasted ? "ENTERTAINMENT" : (modelData.is_productive ? "PRODUCTIVE" : "GENERAL")
                                                color: modelData.is_wasted
                                                    ? (Services.Theme.isDark ? "#ff8080" : "#7a1515")
                                                    : (modelData.is_productive 
                                                        ? (Services.Theme.isDark ? "#80ff80" : "#0f520f")
                                                        : Services.Theme.text)
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Bar showing relative proportion
                                        Rectangle {
                                            property real maxSecs: {
                                                var ua = Services.AmICookedService.stats.usage_analytics;
                                                if (!ua || !ua.lifetime || !ua.lifetime.top_apps || ua.lifetime.top_apps.length === 0) return 1;
                                                return ua.lifetime.top_apps[0].seconds || 1;
                                            }
                                            width: Math.max(4, 120 * (modelData.seconds / maxSecs))
                                            height: 8
                                            color: Services.Theme.isDark ? "#444444" : "#888888"
                                            radius: 4
                                        }

                                        Text { text: modelData.formatted; color: Services.Theme.text; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }
                    }
                }

                // FOOTER INSTRUCTIONS
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "SHORTCUT: Press [ Super + I ] or [ ESC ] to close | Binds to Theme.qml dark/light mode"
                        color: Services.Theme.subtext
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        color: Services.Theme.isDark ? "#222222" : "#dddddd"
                        border.color: Services.Theme.border
                        border.width: 1
                        radius: 4
                        implicitWidth: 70
                        implicitHeight: 24

                        Text {
                            anchors.centerIn: parent
                            text: "REFRESH"
                            color: Services.Theme.text
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.AmICookedService.refresh()
                        }
                    }
                }
            }
        }
    }
}
