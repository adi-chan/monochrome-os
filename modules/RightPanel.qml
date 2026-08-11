// modules/RightPanel.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs.services as Services
import qs.modules
import qs.modules.controlpanel

PopupWindow {
    id: pop

    // Content Colors & Properties
    property color textMain: Services.Theme.text
    property color textSub: Services.Theme.subtext
    property bool open: false
    property Item anchorItem: null
    property int gap: 12
    signal requestClose()

    visible: (open && anchorItem !== null) || closing
    color: "transparent"

    // Active Sidebar Tab (0: Wi-Fi, 1: Ethernet, 2: Bluetooth, 3: Power Profile & Battery)
    property int activeTab: 0

    // Power Profile property tracking
    property string currentProfile: "balanced"
    Process {
        id: profileRead
        command: ["bash", "-c", "busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile | cut -d'\"' -f2"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") pop.currentProfile = text.trim()
        }
    }
    Timer {
        interval: 2000
        repeat: true
        running: pop.visible
        triggeredOnStart: true
        onTriggered: profileRead.running = true
    }

    Process { id: perfProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "performance"]; onExited: profileRead.running = true }
    Process { id: balProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "balanced"]; onExited: profileRead.running = true }
    Process { id: saverProc; command: ["busctl", "set-property", "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile", "s", "power-saver"]; onExited: profileRead.running = true }

    // Wi-Fi Network scanning
    property string wifiStatusText: ""
    property bool wifiBusy: false
    ListModel { id: wifiModel }
    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear()
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0)
                let added = {}
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    const parts = line.replace(/\\:/g, "_").split(":")
                    if (parts.length < 4) continue
                    const active = parts[0] === "yes"
                    const ssid = parts[1]
                    const signal = parseInt(parts[2]) || 0
                    const sec = parts[3]
                    if (!ssid || added[ssid]) continue
                    added[ssid] = true
                    wifiModel.append({
                        active: active,
                        ssid: ssid,
                        signal: signal,
                        secured: sec.length > 0 && sec !== "--"
                    })
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: pop.visible && pop.activeTab === 0
        triggeredOnStart: true
        onTriggered: wifiScanProc.running = true
    }

    // ===== Size =====
    property int contentW: 460
    property int contentH: 400

    // ===== Theme / Shadow =====
    property color panelBg: Services.Theme.bg
    property color panelBorder: Services.Theme.border
    property int panelRadius: 18
    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 5

    // ===== Anim State =====
    property real animY: 0
    property real animScale: 1
    property real animOpacity: 1
    property bool closing: false

    HoverHandler {
        id: rootHover
    }

    property bool buttonHovered: false
    property bool contentHovered: rootHover.hovered
    property bool shouldBeOpen: buttonHovered || contentHovered
    
    onShouldBeOpenChanged: {
        if (!shouldBeOpen) {
            closeTimer.restart()
        } else {
            closeTimer.stop()
        }
    }
    
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: {
            if (pop.open) pop.playCloseAnim()
        }
    }
    implicitWidth: contentW + shadowPad
    implicitHeight: contentH + shadowPad * 2

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
        requestClose()
        closeAnim.restart()
    }

    function updatePos() {}

    onOpenChanged: {
        if (open) {
            playOpenAnim()
        } else if (visible && !closing) {
            playCloseAnim()
        }
    }

    onVisibleChanged: {
        if (visible && open) playOpenAnim()
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
            pop.anchor.rect.y = Math.round(pop.anchorItem.height + 8 - pop.shadowPad)
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
                id: contentMouseArea
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onPressed: mouse.accepted = true
            }

            // ===== MAIN CONTROL CENTER LAYOUT =====
            RowLayout {
                layoutDirection: Qt.RightToLeft
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // ==========================================
                // LEFT SIDEBAR NAVIGATION PILL
                // ==========================================
                Rectangle {
                    Layout.preferredWidth: 50
                    Layout.fillHeight: true
                    radius: 25
                    color: Services.Theme.bgSolid
                    border.color: Services.Theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 10

                        // Icon Tab Data Model
                        Repeater {
                            model: [
                                { icon: "󰤨", name: "Wireless" },
                                { icon: "󰂯", name: "Bluetooth" },
                                { icon: "󰒲", name: "System" },
                                { icon: "󰀘", name: "Shortcuts" }
                            ]

                            delegate: Rectangle {
                                id: tabBtn
                                Layout.alignment: Qt.AlignHCenter
                                width: 38
                                height: 38
                                radius: 19
                                
                                property bool isActive: pop.activeTab === index
                                property bool isHovered: false

                                color: isActive ? Services.Theme.primary : (isHovered ? Services.Theme.highlight : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: 16
                                    color: tabBtn.isActive ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        tabBtn.isHovered = true
                                        pop.activeTab = index
                                    }
                                    onExited: tabBtn.isHovered = false
                                    onClicked: pop.activeTab = index
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ==========================================
                // RIGHT DYNAMIC CONTENT AREA
                // ==========================================
                ColumnLayout {
                    layoutDirection: Qt.LeftToRight
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    // Header (User Profile + Info)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ProfilePicture {}

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: "hello, " + Services.SystemDetails.username
                                color: Services.Theme.text
                                font.pixelSize: 18
                                font.weight: 700
                                font.family: "JetBrains Mono"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 6

                                Text {
                                    text: Services.SystemDetails.osIcon
                                    color: Services.Theme.subtext
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: Services.SystemDetails.uptime
                                    color: Services.Theme.subtext
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Services.Theme.border
                        opacity: 0.7
                    }

                    // DYNAMIC VIEW CONTENT
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        // ------------------------------------------
                        // TAB 0: WIRELESS (Wi-Fi) VIEW
                        // ------------------------------------------
                        ColumnLayout {
                            anchors.fill: parent
                            visible: pop.activeTab === 0
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Wireless"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "JetBrains Mono"
                                    color: Services.Theme.text
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    checked: Services.Network.wifiEnabled
                                    onClicked: Services.Network.toggleWifi()
                                }
                            }

                            Text {
                                text: Services.Network.wifiEnabled ? (Services.Network.connected ? ("Connected: " + Services.Network.ssid) : "Disconnected") : "Wireless Off"
                                font.pixelSize: 12
                                color: Services.Theme.subtext
                            }

                            NetworkSpeed {
                                visible: Services.Network.wifiEnabled
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Services.Theme.bgSolid
                                border.color: Services.Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰤨"; font.family: "JetBrainsMono Nerd Font"; color: Services.Theme.text }
                                    Text { text: "Rescan networks"; font.pixelSize: 12; color: Services.Theme.text; font.family: "JetBrains Mono" }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiScanProc.running = true
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6
                                clip: true
                                model: wifiModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 36
                                    radius: 8
                                    color: model.active ? Services.Theme.primary : Services.Theme.bgSolid
                                    border.color: Services.Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: model.active ? "󰤨" : "󰤟"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 14
                                            color: model.active ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text
                                        }

                                        Text {
                                            text: model.ssid
                                            font.pixelSize: 13
                                            font.family: "JetBrains Mono"
                                            color: model.active ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: model.secured
                                            text: "🔒"
                                            font.pixelSize: 10
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!model.active) {
                                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", model.ssid])
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ------------------------------------------
                        // TAB 1: BLUETOOTH VIEW
                        // ------------------------------------------
                        ColumnLayout {
                            anchors.fill: parent
                            visible: pop.activeTab === 1
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Bluetooth"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "JetBrains Mono"
                                    color: Services.Theme.text
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    checked: Services.Bluetooth.powered
                                    onClicked: Services.Bluetooth.togglePower()
                                }
                            }

                            Text {
                                text: Services.Bluetooth.powered ? (Services.Bluetooth.connected ? ("Connected to " + Services.Bluetooth.deviceName + (Services.Bluetooth.battery !== "" ? " (" + Services.Bluetooth.battery + "%)" : "")) : "Enabled / Discovering") : "Bluetooth Off"
                                font.pixelSize: 12
                                color: Services.Theme.subtext
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Services.Theme.bgSolid
                                border.color: Services.Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "⚙"; font.pixelSize: 12; color: Services.Theme.text }
                                    Text { text: "Open bluetooth settings"; font.pixelSize: 12; color: Services.Theme.text; font.family: "JetBrains Mono" }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "blueman-manager || blueberry || systemsettings5 kcm_bluetooth"])
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6
                                clip: true
                                model: Services.Bluetooth.devicesModel

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 36
                                    radius: 8
                                    color: model.connected ? Services.Theme.primary : Services.Theme.bgSolid
                                    border.color: Services.Theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: model.connected ? "󰂱" : "󰂯"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 14
                                            color: model.connected ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text
                                        }

                                        Text {
                                            text: model.name || "Bluetooth Device"
                                            font.pixelSize: 13
                                            font.family: "JetBrains Mono"
                                            color: model.connected ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.text
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: model.connected ? "Disconnect" : "Connect"
                                            font.pixelSize: 11
                                            color: model.connected ? (Services.Theme.isDark ? "#000000" : "#ffffff") : Services.Theme.subtext
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Services.Bluetooth.connectDevice(model.mac, model.connected)
                                        }
                                    }
                                }
                            }
                        }

                        // ------------------------------------------
                        // TAB 2: SYSTEM VIEW
                        // ------------------------------------------
                        ColumnLayout {
                            anchors.fill: parent
                            visible: pop.activeTab === 2
                            spacing: 12

                            Text {
                                text: "System Info"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "JetBrains Mono"
                                color: Services.Theme.text
                            }
                            
                            System_Details { Layout.fillWidth: true; Layout.fillHeight: true }
                            
                            Item { Layout.fillHeight: true }
                        }

                        // ------------------------------------------
                        // TAB 3: SHORTCUTS VIEW
                        // ------------------------------------------
                        ColumnLayout {
                            anchors.fill: parent
                            visible: pop.activeTab === 3
                            spacing: 12

                            Text {
                                text: "Shortcuts"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "JetBrains Mono"
                                color: Services.Theme.text
                            }
                            
                            QuickApps { Layout.fillWidth: true; Layout.preferredHeight: 60 }
                            QuickScripts { Layout.fillWidth: true; Layout.preferredHeight: 60 }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
}
