import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Popup {
    id: menu
    width: 340
    modal: false
    focus: true
    padding: 10
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Theme
    property color bg: "#181825"
    property color border: "#313244"
    property color text: "#cdd6f4"
    property color subtext: "#a6adc8"
    property color btnBg: "#313244"
    property color btnHover: "#2f3042"
    property color btnPress: "#2a2b3a"

    property string statusText: ""
    property bool busy: false

    ListModel { id: netModel }

    function openFrom(anchorItem) {
        // Use the anchor's visual parent as the popup's parent for correct QQuickItem type
        if (anchorItem && anchorItem.parent) {
            menu.parent = anchorItem.parent
        }
        menu.open()
        Qt.callLater(function() {
            if (!menu.parent) return
            const anchor = anchorItem.mapToItem(menu.parent, anchorItem.width/2, anchorItem.height)
            menu.x = Math.round(anchor.x - menu.width/2)
            menu.y = Math.round(anchor.y + 8)
            if (menu.parent.width) menu.x = Math.max(6, Math.min(menu.x, Math.round(menu.parent.width - menu.width - 6)))
        })
    }

    function refresh() {
        statusText = ""
        netModel.clear()
        listProc.running = false
        listProc.running = true
    }

    function connectWifi(ssid) {
        if (!ssid || busy) return
        busy = true
        statusText = "Connecting to " + ssid + "..."
        actionProc.command = ["bash", "-lc", "nmcli dev wifi connect '" + ssid.replace(/'/g, "'\\''") + "'"]
        actionProc.running = false
        actionProc.running = true
    }

    function wifiIcon(strength, isSecured) {
        let icon = "󰤟"
        if (strength >= 75) icon = "󰤨"
        else if (strength >= 50) icon = "󰤥"
        else if (strength >= 25) icon = "󰤢"
        return icon
    }

    Process {
        id: listProc
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(l => l.trim()).filter(l => l.length > 0)
                let addedSsids = {}
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    const parts = line.replace(/\\:/g, "_").split(":")
                    if (parts.length < 4) continue
                    
                    const active = (parts[0] || "").trim() === "yes"
                    const ssid = (parts[1] || "").trim()
                    const signal = parseInt((parts[2] || "0").trim())
                    const security = (parts[3] || "").trim()

                    if (!ssid || addedSsids[ssid]) continue
                    addedSsids[ssid] = true

                    netModel.append({ 
                        ssid: ssid, 
                        active: active, 
                        signal: isNaN(signal) ? 0 : signal, 
                        security: security 
                    })
                }
                if (netModel.count === 0) statusText = "No networks found."
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

    onOpened: refresh()

    background: Rectangle {
        radius: 16
        color: menu.bg
        border.width: 1
        border.color: menu.border
    }

    contentItem: ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Wi-Fi Networks"
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
                    model: netModel

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
                                text: wifiIcon(model.signal, model.security !== "")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 18
                                color: menu.text
                                Layout.alignment: Qt.AlignVCenter
                                opacity: model.active ? 1.0 : 0.9
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -2

                                Text {
                                    text: model.ssid
                                    color: menu.text
                                    font.pixelSize: 13
                                    font.weight: model.active ? 800 : 600
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.active ? "Connected" : (model.security ? model.security : "Open")
                                    color: menu.subtext
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: model.active ? "Connected" : "Connect"
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
                            enabled: !menu.busy && !model.active
                            onClicked: menu.connectWifi(model.ssid)
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
