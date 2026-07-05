import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.datetimepanel
import qs.modules
import qs.services as Services

PanelWindow {
    id: panel
    visible: false
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property color panelBg: Services.Theme.bg
    property color panelBorder: Services.Theme.border

    property int pageIndex: 0
    property bool remindersExpanded: false
    property bool isOpen: false

    function togglePanelAnimation() {
        if (isOpen) {
            isOpen = false
            hideTimer.start()
        } else {
            panel.visible = true
            isOpen = true
        }
    }

    Timer {
        id: hideTimer
        interval: 800 // match animation duration
        onTriggered: panel.visible = false
    }

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }
    function clamp02(v) { return Math.max(0, Math.min(2, v)) }
    function lerp(a, b, t) { return a + (b - a) * t }

    onVisibleChanged: {
        if (visible) {
            remindersExpanded = false
            pageIndex = 0
        }
    }

    onPageIndexChanged: {
        remindersExpanded = false
    }

    // --- shadow ---
    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 6

    property int contentW: 660
    property int contentH: 330

    implicitWidth: contentW + shadowPad * 2
    implicitHeight: contentH + shadowPad * 2

    // Anchors to only top, which should center it horizontally. 
    anchors { top: true; bottom: false; left: false; right: false }
    margins { top: 6 - shadowPad }

    property int contentPadding: 12
    property int tabsTopGap: -6

    PanelWindow {
        id: backdrop
        color: "transparent"
        visible: panel.visible
        exclusiveZone: -1
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onPressed: if (panel.isOpen) panel.togglePanelAnimation()
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [ panel ]
        active: panel.visible
        onCleared: if (panel.isOpen) panel.togglePanelAnimation()
    }

    Item {
        id: wrap
        anchors.fill: parent
        anchors.margins: panel.shadowPad

        y: panel.isOpen ? 0 : -60
        opacity: panel.isOpen ? 1.0 : 0.0
        scale: panel.isOpen ? 1.0 : 0.85
        transformOrigin: Item.Top

        transform: Rotation {
            origin.x: wrap.width / 2
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: panel.isOpen ? 0 : -35
            Behavior on angle {
                NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 }
            }
        }

        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 } }

        Rectangle {
            anchors.fill: parent
            radius: 16
            antialiasing: true
            color: Services.Theme.bgSolid

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: panel.shadowOpacity
                shadowVerticalOffset: panel.shadowOffsetY
                shadowBlur: panel.shadowBlur
            }
        }

        Rectangle {
            id: clipCard
            anchors.fill: parent
            radius: 16
            color: "transparent"
            clip: true
            antialiasing: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                propagateComposedEvents: false
                onPressed: mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: panel.contentPadding
                spacing: 12

                // =========================
                // TOP MENU
                // =========================
                Item {
                    id: topMenu
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Layout.topMargin: panel.tabsTopGap

                    property int tabLabelVOffset: 1

                    RowLayout {
                        id: tabsRow
                        anchors.fill: parent
                        spacing: 0

                        Item { Layout.fillWidth: true }

                        Item {
                            id: tabDashboard
                            Layout.preferredWidth: dashLabel.implicitWidth
                            Layout.preferredHeight: parent.height
                            readonly property real labelW: dashLabel.implicitWidth
                            readonly property real centerX: x + width / 2

                            Text {
                                id: dashLabel
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: topMenu.tabLabelVOffset
                                text: "Dashboard"
                                color: panel.pageIndex === 0 ? Services.Theme.text : Services.Theme.subtext
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
                                font.weight: panel.pageIndex === 0 ? 700 : 600
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.pageIndex = 0
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Item {
                            id: tabWallpapers
                            Layout.preferredWidth: wallLabel.implicitWidth
                            Layout.preferredHeight: parent.height
                            readonly property real labelW: wallLabel.implicitWidth
                            readonly property real centerX: x + width / 2

                            Text {
                                id: wallLabel
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: topMenu.tabLabelVOffset
                                text: "Wallpapers"
                                color: panel.pageIndex === 1 ? Services.Theme.text : Services.Theme.subtext
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
                                font.weight: panel.pageIndex === 1 ? 700 : 600
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.pageIndex = 1
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Item {
                            id: tabTimer
                            Layout.preferredWidth: timerLabel.implicitWidth
                            Layout.preferredHeight: parent.height
                            readonly property real labelW: timerLabel.implicitWidth
                            readonly property real centerX: x + width / 2

                            Text {
                                id: timerLabel
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: topMenu.tabLabelVOffset
                                text: "Timer"
                                color: panel.pageIndex === 2 ? Services.Theme.text : Services.Theme.subtext
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
                                font.weight: panel.pageIndex === 2 ? 700 : 600
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.pageIndex = 2
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Services.Theme.border
                        opacity: 0.7
                    }

                    Rectangle {
                        id: indicator
                        height: 2
                        radius: 2
                        color: Services.Theme.primary
                        y: topMenu.height - 2

                        readonly property real t: {
                            const w = Math.max(1, pageViewport.width)
                            return panel.clamp02((-pageRow.x) / w)
                        }

                        readonly property real dashCX: tabDashboard.centerX
                        readonly property real wallCX: tabWallpapers.centerX
                        readonly property real timerCX: tabTimer.centerX

                        width: {
                            if (t < 1.0) return Math.max(34, panel.lerp(tabDashboard.labelW + 10, tabWallpapers.labelW + 10, t))
                            else return Math.max(34, panel.lerp(tabWallpapers.labelW + 10, tabTimer.labelW + 10, t - 1.0))
                        }
                        x: {
                            if (t < 1.0) return panel.lerp(dashCX, wallCX, t) - width / 2
                            else return panel.lerp(wallCX, timerCX, t - 1.0) - width / 2
                        }
                    }
                }

                // =========================
                // PAGES
                // =========================
                Item {
                    id: pageViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Row {
                        id: pageRow
                        width: pageViewport.width * 3
                        height: pageViewport.height
                        x: -panel.pageIndex * pageViewport.width

                        Behavior on x { NumberAnimation { duration: 200 } }

                        // -------- Dashboard --------
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height

                            RowLayout {
                                anchors.fill: parent
                                spacing: 12

                                ColumnLayout {
                                    Layout.preferredWidth: 320
                                    Layout.fillHeight: true

                                    Calendar {
                                        anchors.fill: parent
                                        onDateClicked: (year, month, day) => {
                                            addReminderPopup.show(year, month, day)
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Reminders {
                                        anchors.fill: parent
                                        expanded: panel.remindersExpanded
                                        onRequestExpand: panel.remindersExpanded = true
                                        onRequestCollapse: panel.remindersExpanded = false
                                    }
                                }
                            }
                        }

                        // -------- Wallpapers --------
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height

                            Wallpaper {
                                anchors.fill: parent
                            }
                        }

                        // -------- Timer --------
                        Item {
                            width: pageViewport.width
                            height: pageViewport.height

                            TimerWidget {
                                anchors.fill: parent
                            }
                        }
                    }
                }
            }

            Services.ReminderService { id: reminderServiceLocal }

            Rectangle {
                id: addReminderPopup
                anchors.fill: parent
                color: Services.Theme.bgSolid
                visible: false
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                property int yVal: 0
                property int mVal: 0
                property int dVal: 0

                function show(y, m, d) {
                    yVal = y
                    mVal = m
                    dVal = d
                    let now = new Date()
                    hrInput.text = now.getHours().toString().padStart(2, '0')
                    minInput.text = now.getMinutes().toString().padStart(2, '0')
                    titleInput.text = ""
                    visible = true
                    titleInput.forceActiveFocus()
                }

                MouseArea { anchors.fill: parent; hoverEnabled: true }

                Rectangle {
                    anchors.centerIn: parent
                    width: 300
                    height: 200
                    radius: 12
                    color: panelBg
                    border.color: panelBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "Add Reminder (" + addReminderPopup.dVal.toString().padStart(2, '0') + "/" + (addReminderPopup.mVal + 1).toString().padStart(2, '0') + "/" + addReminderPopup.yVal + ")"
                            color: Services.Theme.text
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "JetBrains Mono"
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            Rectangle {
                                width: 50; height: 36
                                color: Services.Theme.bg
                                radius: 6
                                border.width: 1
                                border.color: hrInput.activeFocus ? Services.Theme.primary : Services.Theme.border
                                
                                TextInput {
                                    id: hrInput
                                    anchors.centerIn: parent
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono"
                                    color: Services.Theme.text
                                    text: ""
                                    validator: IntValidator { bottom: 0; top: 23 }
                                    onActiveFocusChanged: if (activeFocus) selectAll()
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onWheel: (wheel) => {
                                        let v = parseInt(hrInput.text) || 0
                                        v = (v + (wheel.angleDelta.y > 0 ? 1 : 23)) % 24
                                        hrInput.text = v.toString().padStart(2, '0')
                                    }
                                }
                            }
                            
                            Text { text: ":"; color: Services.Theme.text; font.pixelSize: 16; font.bold: true; font.family: "JetBrains Mono" }
                            
                            Rectangle {
                                width: 50; height: 36
                                color: Services.Theme.bg
                                radius: 6
                                border.width: 1
                                border.color: minInput.activeFocus ? Services.Theme.primary : Services.Theme.border
                                
                                TextInput {
                                    id: minInput
                                    anchors.centerIn: parent
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono"
                                    color: Services.Theme.text
                                    text: ""
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    onActiveFocusChanged: if (activeFocus) selectAll()
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onWheel: (wheel) => {
                                        let v = parseInt(minInput.text) || 0
                                        v = (v + (wheel.angleDelta.y > 0 ? 1 : 59)) % 60
                                        minInput.text = v.toString().padStart(2, '0')
                                    }
                                }
                            }
                            
                            Text {
                                text: "(Scroll to set)"
                                color: Services.Theme.subtext
                                font.pixelSize: 12
                                Layout.leftMargin: 8
                            }
                        }

                        RowLayout {
                            Text { text: "Title:"; color: Services.Theme.subtext; font.pixelSize: 13 }
                            TextInput {
                                id: titleInput
                                Layout.fillWidth: true
                                color: Services.Theme.text
                                font.pixelSize: 14
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 80; height: 32; radius: 8; color: Services.Theme.secondaryContainer
                                Text { anchors.centerIn: parent; text: "Cancel"; color: Services.Theme.text }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: addReminderPopup.visible = false }
                            }
                            Rectangle {
                                width: 80; height: 32; radius: 8; color: Services.Theme.primary
                                Text { anchors.centerIn: parent; text: "Save"; color: Services.Theme.bg; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let timeStr = hrInput.text.padStart(2, '0') + ":" + minInput.text.padStart(2, '0')
                                        reminderServiceLocal.addReminder(addReminderPopup.yVal, addReminderPopup.mVal, addReminderPopup.dVal, timeStr, titleInput.text)
                                        addReminderPopup.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
