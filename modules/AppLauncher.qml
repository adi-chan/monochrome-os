import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: pop
    property bool open: false
    property Item anchorItem: null

    color: "transparent"
    
    implicitWidth: 420
    implicitHeight: 420
    exclusiveZone: -1
    
    anchors {
        top: true
    }
    margins {
        top: 6
    }
    
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: pop.open
        onActiveChanged: {
            if (!active) pop.open = false
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            pollProc.running = false;
            pollProc.running = true;
        }
    }

    Process {
        id: pollProc
        command: ["bash", "-c", "if [ -f /tmp/qs_toggle_launcher ]; then rm /tmp/qs_toggle_launcher; echo 1; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "1") {
                    pop.open = !pop.open;
                    if (pop.open) {
                        searchInput.text = "";
                        focusTimer.restart();
                    }
                }
            }
        }
    }
    
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: searchInput.forceActiveFocus()
    }

    Process {
        id: updateAppsProc
        command: ["python3", "/home/nick/.config/quickshell/scripts/update_apps.py"]
        onExited: {
            loadApps.running = false;
            loadApps.running = true;
        }
    }



    property var allApps: []
    property var filteredApps: []

    Process {
        id: loadApps
        command: ["cat", "/home/nick/.config/quickshell/assets/apps.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    pop.allApps = JSON.parse(text)
                    pop.filteredApps = pop.allApps
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: loadApps.running = true

    function filter(query) {
        if (!query) {
            filteredApps = allApps;
        } else {
            let q = query.toLowerCase();
            filteredApps = allApps.filter(app => app.name.toLowerCase().includes(q) || (app.desc && app.desc.toLowerCase().includes(q)));
        }
        appView.currentIndex = 0;
    }

    visible: pop.open || hideTimer.running

    onOpenChanged: {
        if (open) {
            searchInput.forceActiveFocus();
            updateAppsProc.running = false;
            updateAppsProc.running = true;
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 350
    }

    Rectangle {
        id: morphRect
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: pop.open ? 420 : (anchorItem ? anchorItem.width : 120)
        height: pop.open ? 420 : (anchorItem ? anchorItem.height : 28)
        radius: pop.open ? 16 : (anchorItem ? anchorItem.radius : 14)
        
        color: "#000000"
        border.color: pop.open ? "#1a1a1a" : "#000000"
        border.width: 1
        
        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
        Behavior on border.color { ColorAnimation { duration: 350; easing.type: Easing.OutExpo } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            
            opacity: pop.open ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: 15
                    color: "#ffffff"
                    selectionColor: "#ffffff"
                    selectedTextColor: "#000000"
                    selectByMouse: true
                    
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps"
                        color: "#666666"
                        font.pixelSize: 15
                        visible: searchInput.text.length === 0
                    }

                    onTextChanged: pop.filter(text)

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            pop.open = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            appView.currentIndex = Math.min(appView.currentIndex + 1, Math.max(0, pop.filteredApps.length - 1));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            appView.currentIndex = Math.max(appView.currentIndex - 1, 0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (appView.currentIndex >= 0 && appView.currentIndex < pop.filteredApps.length) {
                                launchProc.command = ["hyprctl", "dispatch", "exec", pop.filteredApps[appView.currentIndex].exec];
                                launchProc.running = true;
                                pop.open = false;
                            }
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    text: pop.filteredApps.length + " / " + pop.allApps.length
                    font.pixelSize: 12
                    color: "#666666"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#222222"
            }

            ListView {
                id: appView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: pop.filteredApps
                spacing: 4
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 52
                    radius: 12
                    color: appView.currentIndex === index ? "#1a1a1a" : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name ? modelData.name.charAt(0) : "?"
                                color: appView.currentIndex === index ? "#ffffff" : "#999999"
                                font.pixelSize: 16
                                font.bold: true
                                visible: appIcon.status === Image.Error || appIcon.status === Image.Null || !modelData.icon
                            }

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                sourceSize: Qt.size(24, 24)
                                source: modelData.icon ? (modelData.icon.startsWith("/") ? "file://" + modelData.icon : "image://icon/" + modelData.icon) : ""
                                visible: status === Image.Ready && modelData.icon
                                onStatusChanged: {
                                    // if it errors, the Text element becomes visible automatically
                                }
                            }
                        }

                        Text {
                            text: modelData.name
                            color: appView.currentIndex === index ? "#ffffff" : "#cccccc"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.desc || ""
                            color: appView.currentIndex === index ? "#444444" : "#666666"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            Layout.maximumWidth: 160
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            text: "↵"
                            color: "#ffffff"
                            font.pixelSize: 14
                            visible: appView.currentIndex === index
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: appView.currentIndex = index
                        onClicked: {
                            appView.currentIndex = index;
                            launchProc.command = ["hyprctl", "dispatch", "exec", modelData.exec];
                            launchProc.running = true;
                            pop.open = false;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: launchProc
        running: false
    }
}
