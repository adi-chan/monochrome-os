import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    
    implicitWidth: 480

    property bool showingQueue: true
    property string searchQuery: ""
    property int activePlayingIndex: -1
    signal playlistLoaded()

    function showQueue() {
        showingQueue = true
        queueFetchProc.running = false
        queueFetchProc.running = true
        visible = true
    }

    function showLibrary() {
        showingQueue = false
        libraryFetchProc.running = false
        libraryFetchProc.running = true
        visible = true
    }

    HyprlandFocusGrab {
        windows: [ popup ]
        active: popup.visible
        onCleared: popup.visible = false
    }

    ListModel { id: queueModel }
    ListModel { id: libraryModel }

    Process { id: actionProc }

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
        command: ["/home/nick/.config/quickshell/scripts/extract_covers.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                queueModel.clear()
                if (text.trim() === "") return;
                try {
                    const items = JSON.parse(text.trim())
                    let foundPlaying = -1;
                    for (let i = 0; i < items.length; i++) {
                        const item = items[i]
                        const isPlaying = item.isPlaying === "1"
                        queueModel.append({
                            "pos": item.pos,
                            "artist": item.artist,
                            "title": item.title,
                            "time": item.time,
                            "file": item.file,
                            "cover": item.cover || "",
                            "isPlaying": isPlaying
                        })
                        if (isPlaying) foundPlaying = i;
                    }
                    popup.activePlayingIndex = foundPlaying
                    if (foundPlaying !== -1 && popup.showingQueue && popup.visible) {
                        queueList.positionViewAtIndex(foundPlaying, ListView.Center)
                    }
                } catch (e) {
                    console.log("Error parsing playlist JSON:", e)
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

    // Main Container
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Services.Theme.bgSolid
        border.color: Services.Theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.4
            shadowBlur: 1.0
            shadowVerticalOffset: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header Row (Tabs + Close Button)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Glass Pill Tabs Container
                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 12
                    color: Services.Theme.bg
                    border.color: Services.Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        // Queue Tab
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: popup.showingQueue ? (Services.Theme.isDark ? "#2d2f45" : "#d8dee9") : "transparent"
                            border.color: popup.showingQueue ? (Services.Theme.isDark ? "#45475a" : "#cbd5e1") : "transparent"
                            border.width: popup.showingQueue ? 1 : 0
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰎈  Queue"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: popup.showingQueue ? Services.Theme.text : Services.Theme.subtext
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.showQueue()
                            }
                        }

                        // Library Tab
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: !popup.showingQueue ? (Services.Theme.isDark ? "#2d2f45" : "#d8dee9") : "transparent"
                            border.color: !popup.showingQueue ? (Services.Theme.isDark ? "#45475a" : "#cbd5e1") : "transparent"
                            border.width: !popup.showingQueue ? 1 : 0
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰉋  Library"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: !popup.showingQueue ? Services.Theme.text : Services.Theme.subtext
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.showLibrary()
                            }
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: 42; height: 42; radius: 12
                    color: closeMouse.containsMouse ? "#ff4757" : Services.Theme.bg
                    border.color: Services.Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: closeMouse.containsMouse ? "#ffffff" : Services.Theme.text
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.visible = false
                    }
                }
            }

            // Search Bar Input
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: Services.Theme.bg
                border.color: searchInput.activeFocus ? "#3b82f6" : Services.Theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: Services.Theme.subtext
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        color: Services.Theme.text
                        clip: true
                        onTextChanged: popup.searchQuery = text.trim().toLowerCase()

                        Text {
                            text: "Search queue or library..."
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            color: Qt.alpha(Services.Theme.subtext, 0.6)
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    Text {
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: Services.Theme.subtext
                        visible: searchInput.text !== ""
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = ""
                                popup.searchQuery = ""
                            }
                        }
                    }
                }
            }

            // Toolbar Controls Row (Stats + Actions)
            RowLayout {
                Layout.fillWidth: true
                visible: popup.showingQueue
                spacing: 8

                Text {
                    text: queueModel.count + " Songs"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Services.Theme.subtext
                    Layout.fillWidth: true
                }

                // Jump to Playing Button
                Rectangle {
                    height: 28; implicitWidth: 105; radius: 7
                    color: jumpMouse.containsMouse ? Services.Theme.highlight : Services.Theme.bg
                    border.color: Services.Theme.border
                    border.width: 1
                    visible: popup.activePlayingIndex !== -1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰑮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#3b82f6" }
                        Text { text: "Now Playing"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold; color: Services.Theme.text }
                    }
                    MouseArea {
                        id: jumpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (popup.activePlayingIndex !== -1) {
                                queueList.positionViewAtIndex(popup.activePlayingIndex, ListView.Center)
                            }
                        }
                    }
                }

                // Shuffle Button
                Rectangle {
                    height: 28; implicitWidth: 80; radius: 7
                    color: shuffMouse.containsMouse ? Services.Theme.highlight : Services.Theme.bg
                    border.color: Services.Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰒝"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#3b82f6" }
                        Text { text: "Shuffle"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold; color: Services.Theme.text }
                    }
                    MouseArea {
                        id: shuffMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionProc.command = ["mpc", "shuffle"]
                            actionProc.running = false
                            actionProc.running = true
                            queueFetchProc.running = false
                            queueFetchProc.running = true
                        }
                    }
                }

                // Clear Queue Button
                Rectangle {
                    height: 28; implicitWidth: 68; radius: 7
                    color: clearMouse.containsMouse ? "#ff4757" : Services.Theme.bg
                    border.color: Services.Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰆴"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: clearMouse.containsMouse ? "#ffffff" : Services.Theme.subtext }
                        Text { text: "Clear"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold; color: clearMouse.containsMouse ? "#ffffff" : Services.Theme.subtext }
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionProc.command = ["mpc", "clear"]
                            actionProc.running = false
                            actionProc.running = true
                            queueFetchProc.running = false
                            queueFetchProc.running = true
                        }
                    }
                }
            }

            // Main List View Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Services.Theme.bg
                radius: 14
                border.color: Services.Theme.border
                border.width: 1
                clip: true

                // QUEUE LIST
                ListView {
                    id: queueList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: queueModel
                    clip: true
                    spacing: 4
                    visible: popup.showingQueue

                    delegate: Rectangle {
                        id: queueItemRect
                        width: ListView.view.width

                        property bool matchesSearch: {
                            if (!popup.searchQuery) return true
                            return model.title.toLowerCase().includes(popup.searchQuery) ||
                                   model.artist.toLowerCase().includes(popup.searchQuery) ||
                                   model.pos.toString().includes(popup.searchQuery)
                        }

                        property bool rowHovered: delMouse.containsMouse || playBtnMouse.containsMouse || delBtnMouse.containsMouse

                        visible: matchesSearch
                        height: matchesSearch ? 56 : 0
                        radius: 10

                        color: model.isPlaying
                            ? (Services.Theme.isDark ? "#1e293b" : "#e0f2fe")
                            : (queueItemRect.rowHovered ? Services.Theme.highlight : "transparent")
                        
                        border.color: model.isPlaying ? "#3b82f6" : "transparent"
                        border.width: model.isPlaying ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Background MouseArea (plays track when clicking row background)
                        MouseArea {
                            id: delMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 0
                            onClicked: {
                                actionProc.command = ["mpc", "play", model.pos]
                                actionProc.running = false
                                actionProc.running = true
                            }
                        }

                        // Content Row placed at z: 1 so action buttons take priority!
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 10
                            z: 1

                            // Left: Album Art Thumbnail OR Animated Equalizer / Track Number
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 8
                                color: Services.Theme.bg
                                border.color: Qt.alpha(Services.Theme.border, 0.4)
                                border.width: 1
                                clip: true
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    id: coverImg
                                    anchors.fill: parent
                                    source: model.cover ? "file://" + model.cover : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    asynchronous: true
                                }

                                // Fallback when image is missing: Animated Equalizer or Track Number
                                Item {
                                    anchors.fill: parent
                                    visible: coverImg.status !== Image.Ready

                                    // Animated Equalizer when playing
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        visible: model.isPlaying
                                        height: 12

                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: 3
                                                height: 4
                                                radius: 1
                                                color: "#3b82f6"
                                                anchors.bottom: parent.bottom

                                                SequentialAnimation on height {
                                                    running: model.isPlaying
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: index === 0 ? 12 : (index === 1 ? 7 : 10); duration: 220 + index*40; easing.type: Easing.InOutQuad }
                                                    NumberAnimation { to: 3; duration: 200 + index*30; easing.type: Easing.InOutQuad }
                                                    NumberAnimation { to: index === 0 ? 6 : (index === 1 ? 10 : 8); duration: 190 + index*50; easing.type: Easing.InOutQuad }
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.pos
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Services.Theme.subtext
                                        visible: !model.isPlaying
                                    }
                                }
                            }

                            // Middle: Title & Artist
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: model.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    font.weight: model.isPlaying ? Font.Bold : Font.DemiBold
                                    color: model.isPlaying ? "#60a5fa" : Services.Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.artist
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    color: Services.Theme.subtext
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Right: Duration & Hover Actions
                            RowLayout {
                                spacing: 6

                                Text {
                                    text: model.time
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                    color: Services.Theme.subtext
                                    visible: !queueItemRect.rowHovered
                                }

                                // Quick Play Action Button
                                Rectangle {
                                    width: 28; height: 28; radius: 7
                                    color: playBtnMouse.containsMouse ? "#3b82f6" : Services.Theme.bg
                                    visible: queueItemRect.rowHovered
                                    z: 10

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰐊"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: playBtnMouse.containsMouse ? "#ffffff" : Services.Theme.text
                                    }
                                    MouseArea {
                                        id: playBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionProc.command = ["mpc", "play", model.pos]
                                            actionProc.running = false
                                            actionProc.running = true
                                        }
                                    }
                                }

                                // Trash Bin / Remove Action Button
                                Rectangle {
                                    width: 28; height: 28; radius: 7
                                    color: delBtnMouse.containsMouse ? "#ff4757" : Services.Theme.bg
                                    visible: queueItemRect.rowHovered
                                    z: 10

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: delBtnMouse.containsMouse ? "#ffffff" : Services.Theme.subtext
                                    }
                                    MouseArea {
                                        id: delBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionProc.command = ["mpc", "del", model.pos]
                                            actionProc.running = false
                                            actionProc.running = true
                                            queueFetchProc.running = false
                                            queueFetchProc.running = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // LIBRARY LIST
                ListView {
                    id: libraryList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: libraryModel
                    clip: true
                    spacing: 4
                    visible: !popup.showingQueue

                    delegate: Rectangle {
                        id: libItemRect
                        width: ListView.view.width

                        property bool matchesSearch: {
                            if (!popup.searchQuery) return true
                            return model.folderName.toLowerCase().includes(popup.searchQuery)
                        }

                        property bool libRowHovered: libDelMouse.containsMouse || addQueueMouse.containsMouse || playLibMouse.containsMouse

                        visible: matchesSearch
                        height: matchesSearch ? 54 : 0
                        radius: 10
                        color: libItemRect.libRowHovered ? Services.Theme.highlight : "transparent"

                        // Background MouseArea (loads folder on row click)
                        MouseArea {
                            id: libDelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 0
                            onClicked: {
                                actionProc.command = ["bash", "-c", "mpc clear; mpc add \"" + model.folderName + "\"; mpc play"]
                                actionProc.running = false
                                actionProc.running = true
                                popup.visible = false
                                popup.playlistLoaded()
                            }
                        }

                        // Content Row at z: 1
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            z: 1

                            Text {
                                text: "󰉋"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                color: "#3b82f6"
                            }

                            Text {
                                text: model.folderName
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Services.Theme.text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Actions on Hover
                            RowLayout {
                                visible: libItemRect.libRowHovered
                                spacing: 6
                                z: 10

                                // Append to Queue Button
                                Rectangle {
                                    height: 28; implicitWidth: 64; radius: 7
                                    color: addQueueMouse.containsMouse ? "#3b82f6" : Services.Theme.bg
                                    border.color: Services.Theme.border
                                    border.width: 1
                                    z: 10

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "󰐕"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: addQueueMouse.containsMouse ? "#ffffff" : Services.Theme.text }
                                        Text { text: "Add"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold; color: addQueueMouse.containsMouse ? "#ffffff" : Services.Theme.text }
                                    }
                                    MouseArea {
                                        id: addQueueMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionProc.command = ["mpc", "add", model.folderName]
                                            actionProc.running = false
                                            actionProc.running = true
                                            queueFetchProc.running = false
                                            queueFetchProc.running = true
                                        }
                                    }
                                }

                                // Play Replace Button
                                Rectangle {
                                    height: 28; implicitWidth: 64; radius: 7
                                    color: playLibMouse.containsMouse ? "#3b82f6" : Services.Theme.bg
                                    border.color: Services.Theme.border
                                    border.width: 1
                                    z: 10

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "󰐊"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: playLibMouse.containsMouse ? "#ffffff" : Services.Theme.text }
                                        Text { text: "Play"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold; color: playLibMouse.containsMouse ? "#ffffff" : Services.Theme.text }
                                    }
                                    MouseArea {
                                        id: playLibMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            actionProc.command = ["bash", "-c", "mpc clear; mpc add \"" + model.folderName + "\"; mpc play"]
                                            actionProc.running = false
                                            actionProc.running = true
                                            popup.visible = false
                                            popup.playlistLoaded()
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
}
