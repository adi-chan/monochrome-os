import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: menu

    property bool open: false
    property Item anchorItem: null
    property int gap: 10
    signal requestClose()

    visible: (open && anchorItem !== null) || closing
    color: "transparent"

    // Theme
    property color bg: Services.Theme.bgSolid
    property color border: Services.Theme.border
    property color text: Services.Theme.text
    property color subtext: Services.Theme.subtext
    property color btnBg: "transparent"
    property color btnHover: Services.Theme.highlight
    property color btnPress: Services.Theme.border

    property int panelRadius: 16
    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 6

    property real animY: 0
    property real animScale: 1
    property real animOpacity: 1
    property bool closing: false

    property string statusText: ""
    property bool busy: false

    ListModel { id: devModel }
    function refresh() {
        statusText = ""
        devModel.clear()
        listProc.running = false
        listProc.running = true
    }

    function runBt(cmd) {
        busy = true
        statusText = "Working…"
        actionProc.command = ["bash", "-lc", cmd + " 2>/dev/null || true"]
        actionProc.running = false
        actionProc.running = true
    }

    function connectFlow(mac, paired, connected) {
        if (!mac || busy) return
        if (connected) {
            runBt("bluetoothctl disconnect " + mac)
            return
        }
        if (paired) {
            runBt("bluetoothctl connect " + mac)
            return
        }
        runBt([
            "bluetoothctl pair " + mac,
            "bluetoothctl trust " + mac,
            "bluetoothctl connect " + mac
        ].join(" && "))
    }



    Process {
        id: listProc
        command: ["bash", "-lc",
            "bluetoothctl devices paired | awk '{print $2}' | while read mac; do " +
            "  info=$(bluetoothctl info $mac); " +
            "  name=$(echo \"$info\" | sed -n 's/^\\s*Name: //p' | head -n1); " +
            "  conn=$(echo \"$info\" | grep -q \"Connected: yes\" && echo yes || echo no); " +
            "  pair=$(echo \"$info\" | grep -q \"Paired: yes\" && echo yes || echo no); " +
            "  trust=$(echo \"$info\" | grep -q \"Trusted: yes\" && echo yes || echo no); " +
            "  echo \"$mac\\t${name:-Unknown}\\t$conn\\t$pair\\t$trust\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0)
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("\t")
                    const mac = (parts[0] || "").trim()
                    const name = (parts[1] || "Unknown").trim()
                    const connected = (parts[2] || "no").trim() === "yes"
                    const paired = (parts[3] || "no").trim() === "yes"
                    const trusted = (parts[4] || "no").trim() === "yes"

                    if (!mac) continue
                    devModel.append({ mac, name, connected, paired, trusted })
                }
                if (devModel.count === 0) statusText = "No paired devices."
            }
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {
            onStreamFinished: {
                const msg = text.trim()
                if (msg) statusText = msg
            }
        }
        onExited: {
            busy = false
            statusText = ""
            refresh()
        }
    }

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
        open = false
        requestClose()
        closeAnim.restart()
    }

    function openFrom(item) {
        if (open || closing) {
            playCloseAnim()
            return
        }
        anchorItem = item
        open = true
    }

    onOpenChanged: {
        if (open && anchorItem !== null) {
            refresh()
        } else if (!open && visible && !closing) {
            playCloseAnim()
        }
    }

    onVisibleChanged: {
        if (visible && open) playOpenAnim()
    }

    LazyLoader {
        id: backdropLoader
        activeAsync: menu.open && !menu.closing

        PanelWindow {
            id: backdrop
            color: "transparent"
            visible: true
            exclusiveZone: -1
            anchors { top: true; bottom: true; left: true; right: true }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                onPressed: menu.playCloseAnim()
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [ menu ]
        active: menu.visible && !menu.closing
        onCleared: menu.playCloseAnim()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: menu.playCloseAnim()
    }

    ParallelAnimation {
        id: openAnim
        SequentialAnimation {
            NumberAnimation { target: menu; property: "animY"; from: -14; to: 3; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: menu; property: "animY"; from: 3; to: 0; duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        }
        SequentialAnimation {
            NumberAnimation { target: menu; property: "animScale"; from: 0.975; to: 1.03; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: menu; property: "animScale"; from: 1.03; to: 1.0; duration: 190; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
        }
        NumberAnimation { target: menu; property: "animOpacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        SequentialAnimation {
            NumberAnimation { target: menu; property: "animY"; from: 0; to: 2; duration: 70; easing.type: Easing.OutCubic }
            NumberAnimation { target: menu; property: "animY"; from: 2; to: -10; duration: 140; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: menu; property: "animScale"; from: 1.0; to: 0.98; duration: 170; easing.type: Easing.InCubic }
        NumberAnimation { target: menu; property: "animOpacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
        onStopped: menu.closing = false
    }

    anchor.item: anchorItem
    Connections {
        target: menu.anchor
        function onAnchoring() {
            if (!menu.anchorItem) return
            menu.anchor.rect.x = Math.round(menu.anchorItem.width / 2 - menu.width / 2)
            menu.anchor.rect.y = Math.round(menu.anchorItem.height + menu.gap - menu.shadowPad)
            menu.anchor.rect.width = 1
            menu.anchor.rect.height = 1
        }
    }

    implicitWidth: Math.round(340 + menu.shadowPad * 2)
    implicitHeight: Math.round(contentCol.implicitHeight + 20 + menu.shadowPad * 2)

    Item {
        id: animWrap
        anchors.fill: parent
        anchors.margins: menu.shadowPad
        y: menu.animY
        scale: menu.animScale
        opacity: menu.animOpacity
        transformOrigin: Item.Top

        Rectangle {
            id: card
            anchors.fill: parent
            radius: menu.panelRadius
            color: menu.bg
            border.width: 1
            border.color: menu.border
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: menu.shadowOpacity
                shadowVerticalOffset: menu.shadowOffsetY
                shadowBlur: menu.shadowBlur
            }
        }

        Rectangle {
            id: clipper
            anchors.fill: parent
            radius: menu.panelRadius
            color: "transparent"
            clip: true
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                hoverEnabled: true
                propagateComposedEvents: false
                onPressed: mouse.accepted = true
                onClicked: mouse.accepted = true
            }

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Bluetooth"
                        color: menu.text
                        font.pixelSize: 14
                        font.weight: 700
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 10
                        color: refreshMouse.pressed ? menu.btnPress : (refreshMouse.containsMouse ? menu.btnHover : menu.btnBg)
                        border.width: 1
                        border.color: Services.Theme.border
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰑓"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 14
                            color: menu.text
                            opacity: 0.95
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: menu.refresh()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    radius: 1
                    color: menu.border
                    opacity: 0.9
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    clip: true
                    contentWidth: width
                    contentHeight: listCol.implicitHeight

                    Column {
                        id: listCol
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: devModel

                            Rectangle {
                                width: parent.width
                                height: 44
                                radius: 14
                                color: rowMouse.pressed ? menu.btnPress : (rowMouse.containsMouse ? menu.btnHover : menu.btnBg)
                                border.width: 1
                                border.color: Services.Theme.border
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    Text {
                                        text: model.connected ? "󰂱" : "󰂯"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 18
                                        color: menu.text
                                        Layout.alignment: Qt.AlignVCenter
                                        opacity: model.connected ? 1.0 : 0.9
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: -2

                                        Text {
                                            text: model.name
                                            color: menu.text
                                            font.pixelSize: 13
                                            font.weight: model.connected ? 800 : 600
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: model.connected ? "Connected" : (model.paired ? "Paired" : "Not paired")
                                            color: menu.subtext
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: model.connected ? "Disconnect" : "Connect"
                                        color: menu.subtext
                                        font.pixelSize: 11
                                        opacity: 0.95
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !menu.busy
                                    onClicked: menu.connectFlow(model.mac, model.paired, model.connected)
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: menu.statusText
                    color: menu.subtext
                    font.pixelSize: 11
                    opacity: 0.95
                    visible: menu.statusText.length > 0
                    elide: Text.ElideRight
                }
            }
        }
    }
}
