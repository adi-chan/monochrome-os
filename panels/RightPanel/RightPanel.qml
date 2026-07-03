// modules/LeftPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs.services as Services
import qs.bar.applets
import qs.panels.RightPanel
import qs.panels.WidgetPanel
import qs.panels.Launchers
import qs.panels.Notifications
import qs.panels.Power
import qs.panels.Media
import qs.panels.OSD
import qs.panels.RightPanel.components

PopupWindow {
    id: pop

    // Content Colors
    property color textMain: Services.Theme.text
    property color textSub: Services.Theme.subtext
    property bool open: false
    property Item anchorItem: null
    property int gap: 6
    signal requestClose()

    visible: (open && anchorItem !== null) || closing
    color: "transparent"

    // ===== Size (content) =====
    property int contentW: 360
    property int contentH: 380

    // ===== Theme / Shadow =====
    property color panelBg: Services.Theme.bg // Neutral dark grey
    property color panelBorder: Services.Theme.border // Neutral border
    property int panelRadius: 16
    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 5

    // ===== Anim State =====
    property real animY: 0
    property real animScale: 1
    property real animOpacity: 1
    property bool closing: false

    width: contentW + shadowPad
    height: contentH + shadowPad * 2

    function playOpenAnim() {
        closing = false
        animY = -14
        animScale = 0.975
        animOpacity = 0
        openAnim.restart()
    }

    function playCloseAnim() {
        if (closing) return
        closing = true
        focusGrab.active = false
        requestClose()
        closeAnim.restart()
    }

    function updatePos() {}

    onOpenChanged: {
        if (!open && visible && !closing) playCloseAnim()
    }

    onVisibleChanged: {
        if (visible && open) playOpenAnim()
    }

    // ===== BACKDROP =====
    LazyLoader {
        id: backdropLoader
        activeAsync: pop.visible

        PanelWindow {
            color: "transparent"
            visible: true
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onPressed: pop.playCloseAnim()
            }
        }
    }

    // ===== Focus Grab / Escape =====
    HyprlandFocusGrab {
        id: focusGrab
        windows: [ pop ]
        active: pop.visible && !pop.closing
        onCleared: pop.playCloseAnim()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: pop.playCloseAnim()
    }

    // ===== Animations =====
    ParallelAnimation {
        id: openAnim
        SequentialAnimation {
            NumberAnimation { target: pop; property: "animY"; from: -14; to: 3; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animY"; from: 3; to: 0; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        }
        SequentialAnimation {
            NumberAnimation { target: pop; property: "animScale"; from: 0.975; to: 1.03; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animScale"; from: 1.03; to: 1.0; duration: 190; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
        }
        NumberAnimation { target: pop; property: "animOpacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        SequentialAnimation {
            NumberAnimation { target: pop; property: "animY"; from: 0; to: 2; duration: 70; easing.type: Easing.OutCubic }
            NumberAnimation { target: pop; property: "animY"; from: 2; to: -10; duration: 140; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: pop; property: "animScale"; from: 1.0; to: 0.98; duration: 170; easing.type: Easing.InCubic }
        NumberAnimation { target: pop; property: "animOpacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
        onStopped: pop.closing = false
    }

    // ===== Anchoring =====
    anchor.item: anchorItem
    Connections {
        target: pop.anchor
        function onAnchoring() {
            if (!pop.anchorItem) return
            pop.anchor.rect.x = Math.round(pop.anchorItem.width - pop.contentW)
            pop.anchor.rect.y = Math.round(pop.anchorItem.height + pop.gap - pop.shadowPad)
            pop.anchor.rect.width = 1
            pop.anchor.rect.height = 1
        }
    }

    // ===== Animated Wrapper =====
    Item {
        id: animWrap
        anchors.fill: parent
        anchors.leftMargin: pop.shadowPad
        anchors.topMargin: pop.shadowPad
        anchors.bottomMargin: pop.shadowPad
        anchors.rightMargin: 2

        y: pop.animY
        scale: pop.animScale
        opacity: pop.animOpacity
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            radius: pop.panelRadius
            color: panelBg
            border.color: panelBorder
            border.width: 1
            
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
            antialiasing: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: pop.shadowOpacity
                shadowVerticalOffset: pop.shadowOffsetY
                shadowBlur: pop.shadowBlur
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: pop.panelRadius
            color: "transparent"
            clip: true
            antialiasing: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onPressed: mouse.accepted = true
            }

            // ===== CONTENT =====
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ProfilePicture {}

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: "hello, " + Services.SystemDetails.username
                            color: Services.Theme.text
                            font.pixelSize: 22
                            font.weight: 600
                            font.family: "JetBrains Mono"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 8

                            Text {
                                text: Services.SystemDetails.osIcon
                                color: Services.Theme.text
                                font.pixelSize: 18
                            }

                            Text {
                                text: Services.SystemDetails.uptime
                                color: Services.Theme.text
                                opacity: 0.85
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Services.Theme.border
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Network { 
                        id: networkCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        onMenuRequested: networkMenu.openFrom(networkCard, pop)
                    }
                    Bluetooth { 
                        id: bluetoothCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        onMenuRequested: bluetoothMenu.openFrom(bluetoothCard, pop)
                    }
                   // Inhibitor { Layout.fillWidth: true; Layout.preferredHeight: 60 }
                    System_Details { Layout.fillWidth: true; Layout.preferredHeight: 60 }
                    QuickApps { Layout.fillWidth: true; Layout.preferredHeight: 60 }
                }

                NetworkMenu { id: networkMenu }
                BluetoothMenu { id: bluetoothMenu }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Services.Theme.border
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                QuickScripts { Layout.fillWidth: true }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
