import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services as Services

PanelWindow {
    id: popup
    visible: false
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; bottom: true; left: false; right: true }
    margins { top: 20; bottom: 20; right: 20 }
    
    implicitWidth: 450

    property bool showingQueue: true
    signal playlistLoaded()

    function showQueue() {
        showingQueue = true
        queueFetchProc.running = false
        queueFetchProc.running = true
        visible = true
    }

    function showLibrary() {
        showingQueue = false
        visible = true
    }

    HyprlandFocusGrab {
        windows: [ popup ]
        active: popup.visible
        onCleared: popup.visible = false
    }

    ListModel { id: queueModel }
    ListModel { id: libraryModel }

    Process {
        id: libraryFetchProc
        command: ["mpc", "ls"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                libraryModel.clear()
                if (text.trim() === "") return;
                const lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") {
                        libraryModel.append({ "folderName": lines[i].trim() })
                    }
                }
            }
        }
    }

    Process {
        id: queueFetchProc
        command: ["bash", "-c", "mpc playlist | awk -v cur=\"$(mpc current -f '%position%')\" '{print NR\"|\"$0\"|\" (NR==cur ? \"1\" : \"0\")}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                queueModel.clear()
                if (text.trim() === "") return;
                const lines = text.trim().split("\n")
                let playingIndex = -1;
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("|")
                    if (parts.length >= 3) {
                        queueModel.append({
                            "pos": parts[0],
                            "title": parts[1] || "",
                            "artist": "",
                            "time": "",
                            "isPlaying": parts[2] === "1"
                        })
                        if (parts[2] === "1") playingIndex = i;
                    }
                }
                if (playingIndex !== -1 && popup.showingQueue && popup.visible) {
                    queueList.positionViewAtIndex(playingIndex, ListView.Center)
                }
            }
        }
    }

    Process {
        id: queueIdleProc
        command: ["mpc", "idleloop", "playlist", "player"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                queueFetchProc.running = false
                queueFetchProc.running = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Services.Theme.bgSolid
        border.color: Services.Theme.border
        border.width: 1

        // Tabs
        RowLayout {
            id: tabRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: popup.showingQueue ? Services.Theme.bg : "transparent"
                radius: 16
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 16; color: Services.Theme.bg; visible: popup.showingQueue
                }
                Text {
                    anchors.centerIn: parent
                    text: "Queue"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    font.weight: 800
                    color: popup.showingQueue ? Services.Theme.primary : Services.Theme.text
                }
                MouseArea { anchors.fill: parent; onClicked: popup.showQueue() }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: !popup.showingQueue ? Services.Theme.bg : "transparent"
                radius: 16
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 16; color: Services.Theme.bg; visible: !popup.showingQueue
                }
                Text {
                    anchors.centerIn: parent
                    text: "Library"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    font.weight: 800
                    color: !popup.showingQueue ? Services.Theme.primary : Services.Theme.text
                }
                MouseArea { anchors.fill: parent; onClicked: popup.showLibrary() }
            }
        }

        // Close button floating
        Rectangle {
            width: 32; height: 32; radius: 16
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 14
            color: closeMouse.containsMouse ? Services.Theme.highlight : Services.Theme.bgSolid
            z: 10
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: Services.Theme.text }
            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: popup.visible = false }
        }

        Rectangle {
            anchors.top: tabRow.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: Services.Theme.bg
            radius: 16
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 16; color: Services.Theme.bg }

            // Queue List
            ListView {
                id: queueList
                anchors.fill: parent
                anchors.margins: 12
                model: queueModel
                clip: true
                spacing: 4
                visible: popup.showingQueue

                Process { id: playTrackProc }
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 54
                    radius: 8
                    color: delMouse.containsMouse ? Services.Theme.highlight : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: model.isPlaying ? "󰐊" : model.pos
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: model.isPlaying ? 20 : 14
                            color: model.isPlaying ? Services.Theme.primary : Services.Theme.subtext
                            Layout.preferredWidth: 32
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                text: model.title
                                font.family: "JetBrains Mono"
                                font.pixelSize: 15
                                font.weight: 600
                                color: model.isPlaying ? Services.Theme.primary : Services.Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: model.artist
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13
                                color: Services.Theme.subtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: model.time
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            color: Services.Theme.subtext
                        }
                    }

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            playTrackProc.command = ["mpc", "play", model.pos]
                            playTrackProc.running = false
                            playTrackProc.running = true
                        }
                    }
                }
            }

            // Library List
            ListView {
                id: libraryList
                anchors.fill: parent
                anchors.margins: 12
                model: libraryModel
                clip: true
                spacing: 4
                visible: !popup.showingQueue

                Process { id: loadPlaylistProc }
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 54
                    radius: 8
                    color: libDelMouse.containsMouse ? Services.Theme.highlight : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: "󰉋"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: Services.Theme.primary
                        }
                        
                        Text {
                            text: model.folderName
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.weight: 600
                            color: Services.Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: libDelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            loadPlaylistProc.command = ["bash", "-c", "mpc clear; mpc add \"" + model.folderName + "\"; mpc play"]
                            loadPlaylistProc.running = false
                            loadPlaylistProc.running = true
                            popup.visible = false
                            popup.playlistLoaded()
                        }
                    }
                }
            }
        }
    }
}
