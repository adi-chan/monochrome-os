import Quickshell
import Quickshell.Io
import QtQuick
import qs.services as Services
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: panel
    visible: false
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool isOpen: false

    function togglePanelAnimation() {
        if (isOpen) {
            isOpen = false
            hideTimer.start()
        } else {
            panel.visible = true
            isOpen = true
            fetchHistoryProc.running = true
        }
    }

    Timer {
        id: hideTimer
        interval: 800
        onTriggered: panel.visible = false
    }

    // --- shadow ---
    property int shadowPad: 10
    property real shadowOpacity: 0.28
    property real shadowBlur: 0.55
    property int shadowOffsetY: 6

    property int contentW: 380
    property int contentH: 500

    implicitWidth: contentW + shadowPad * 2
    implicitHeight: contentH + shadowPad * 2

    // Anchors to top and right to align with the button position
    anchors { top: true; bottom: false; left: false; right: true }
    margins { top: 6 - shadowPad; right: 16 - shadowPad }

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

    Process {
        id: fetchHistoryProc
        command: ["dunstctl", "history"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let json = JSON.parse(text)
                    let notifs = json.data[0] || []
                    notifModel.clear()
                    for (let i = 0; i < notifs.length; i++) {
                        let n = notifs[i]
                        notifModel.append({
                            appname: n.appname ? n.appname.data : "",
                            summary: n.summary ? n.summary.data : "",
                            body: n.body ? n.body.data : "",
                            icon_path: n.icon_path ? n.icon_path.data : ""
                        })
                    }
                } catch (e) {
                    console.log("Failed to parse dunst history:", e)
                }
            }
        }
    }

    Process {
        id: clearHistoryProc
        command: ["dunstctl", "history-clear"]
        running: false
        onExited: {
            notifModel.clear()
        }
    }

    Process {
        id: openProc
        command: ["thunar", ""]
        running: false
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
                anchors.margins: 16
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Notifications"
                        color: Services.Theme.text
                        font.pixelSize: 18
                        font.family: "JetBrains Mono"
                        font.weight: 800
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        width: 80
                        height: 28
                        radius: 6
                        color: Services.Theme.bg
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Services.Theme.text
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clearHistoryProc.running = true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Services.Theme.bg
                    opacity: 0.7
                }

                // List
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: ListModel { id: notifModel }
                    
                    Text {
                        visible: listView.count === 0
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: Services.Theme.subtext
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                    }
                    
                    delegate: Rectangle {
                        width: listView.width
                        height: contentCol.implicitHeight + 24
                        radius: 8
                        color: Services.Theme.bg
                        border.color: Services.Theme.bg
                        border.width: 1
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.icon_path !== "") {
                                    let path = model.icon_path.replace(".thumb.jpg", "")
                                    let dir = path.substring(0, path.lastIndexOf('/'))
                                    openProc.command = ["thunar", dir]
                                    openProc.running = true
                                    panel.togglePanelAnimation() // Close the panel after clicking
                                }
                            }
                        }
                        
                        RowLayout {
                            id: contentCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Image / Icon
                            Image {
                                visible: model.icon_path !== ""
                                source: model.icon_path !== "" ? ("file://" + model.icon_path) : ""
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 64
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 64
                                sourceSize.height: 64
                                // Rounded corners for image
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: ShaderEffectSource {
                                        sourceItem: Rectangle {
                                            width: 64
                                            height: 64
                                            radius: 6
                                        }
                                    }
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 4
                                
                                Text {
                                    text: model.appname
                                    color: Services.Theme.subtext
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                }
                                
                                Text {
                                    text: model.summary
                                    color: Services.Theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "JetBrains Mono"
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: model.body.replace(/<[^>]*>?/gm, '') // Strip basic HTML if any
                                    color: Services.Theme.subtext
                                    font.pixelSize: 13
                                    font.family: "JetBrains Mono"
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
