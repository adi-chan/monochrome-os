import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services as Services
import QtQuick.Controls

Item {
    id: root
    clip: true

    property string title: Services.Mpris.albumTitle
    property string artist: Services.Mpris.albumArtist
    property string artUrl: Services.Mpris.artUrl
    
    property bool shuffleMode: false
    property string loopMode: "None"

    Process {
        id: shuffleSetProc
        onExited: { shuffleGetProc.running = false; shuffleGetProc.running = true }
    }
    Process {
        id: shuffleGetProc
        command: ["bash", "-lc", Services.Mpris.playerArgs.join(" ") + " shuffle 2>/dev/null || echo Off"]
        stdout: StdioCollector {
            onStreamFinished: { root.shuffleMode = (text.trim() === "On") }
        }
    }
    
    Process {
        id: loopSetProc
        onExited: { loopGetProc.running = false; loopGetProc.running = true }
    }
    Process {
        id: loopGetProc
        command: ["bash", "-lc", Services.Mpris.playerArgs.join(" ") + " loop 2>/dev/null || echo None"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = text.trim()
                root.loopMode = (v === "Track" || v === "Playlist" || v === "None") ? v : "None"
            }
        }
    }

    property string currentTimeString: ""

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { 
            shuffleGetProc.running = false; shuffleGetProc.running = true 
            loopGetProc.running = false; loopGetProc.running = true 
            
            let d = new Date()
            let h = d.getHours()
            let m = d.getMinutes()
            let ampm = h >= 12 ? "PM" : "AM"
            h = h % 12
            h = h ? h : 12
            m = m < 10 ? '0' + m : m
            root.currentTimeString = h + ":" + m + " " + ampm
        }
    }

    function toggleShuffle() {
        const next = shuffleMode ? "Off" : "On"
        shuffleSetProc.command = Services.Mpris.playerArgs.concat(["shuffle", next])
        shuffleSetProc.running = false
        shuffleSetProc.running = true
    }

    function cycleLoop() {
        const next = (loopMode === "None") ? "Playlist"
                   : (loopMode === "Playlist") ? "Track"
                   : "None"
        loopSetProc.command = Services.Mpris.playerArgs.concat(["loop", next])
        loopSetProc.running = false
        loopSetProc.running = true
    }
    // Fallback gradient if no art is available
    Rectangle {
        id: rootRect
        anchors.fill: parent
        radius: 12
        color: Services.Theme.bgSolid
        border.color: Services.Theme.border
        border.width: 1
        
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: rootRect.width
                    height: rootRect.height
                    radius: rootRect.radius
                }
            }
        }

        // Background blurred art
        Image {
            id: bgArt
            anchors.fill: parent
            source: root.artUrl !== "" ? root.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.8
            visible: false
            asynchronous: true
        }

        MultiEffect {
            source: bgArt
            anchors.fill: bgArt
            blurEnabled: true
            blurMax: 96
            blur: 1.0
            opacity: bgArt.source.toString() !== "" ? 0.8 : 0
        }

        // Dark overlay to ensure text readability
        Rectangle {
            anchors.fill: parent
            color: Services.Theme.bgSolid
            opacity: 0.3
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24

            // Left side: Album Art
            Rectangle {
                id: artContainer
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                radius: 16
                color: Services.Theme.bg

                // Album art bloom shadow (colored glow)
                Image {
                    anchors.fill: parent
                    source: mainArt.source
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    id: bloomSrc
                }
                MultiEffect {
                    source: bloomSrc
                    anchors.fill: bloomSrc
                    anchors.margins: -4
                    blurEnabled: true
                    blurMax: 48
                    blur: 1.0
                    opacity: 0.65
                    z: -1
                }

                Image {
                    id: mainArt
                    anchors.fill: parent
                    source: root.artUrl !== "" ? root.artUrl : "file:///home/nick/.config/quickshell/assets/music_fallback.svg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: artHover.containsMouse ? 0.05 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: mainArt.width
                                height: mainArt.height
                                radius: 16
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.currentTimeString
                    font.family: "JetBrains Mono"
                    font.weight: 800
                    font.pixelSize: 36
                    color: Services.Theme.text
                    opacity: artHover.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    z: 10
                }

                MouseArea {
                    id: artHover
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 11
                }
                
                // Fallback icon if no art
                Text {
                    anchors.centerIn: parent
                    visible: root.artUrl === ""
                    text: ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 48
                    color: Services.Theme.subtext
                }
            }

            // Right side: Info and Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Item { Layout.fillHeight: true } // Spacer

                // Track Info and App Switcher
                RowLayout {
                    Layout.fillWidth: true
                    z: 100
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28 // Approximate height for 22px text
                            clip: true
                            
                            Row {
                                id: titleRow
                                spacing: 40
                                
                                Text {
                                    id: titleText
                                    text: root.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 22
                                    font.weight: 800
                                    color: Services.Theme.text
                                }
                                Text {
                                    text: root.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 22
                                    font.weight: 800
                                    color: Services.Theme.text
                                    visible: titleText.implicitWidth > titleRow.parent.width
                                }
                                
                                NumberAnimation on x {
                                    running: titleText.implicitWidth > titleRow.parent.width
                                    from: 0
                                    to: -(titleText.implicitWidth + 40)
                                    duration: (titleText.implicitWidth + 40) * 25
                                    loops: Animation.Infinite
                                }
                                
                                Connections {
                                    target: root
                                    function onTitleChanged() { titleRow.x = 0 }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20 // Approximate height for 16px text
                            clip: true

                            Row {
                                id: artistRow
                                spacing: 40

                                Text {
                                    id: artistText
                                    text: root.artist
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 16
                                    color: Services.Theme.subtext
                                }
                                Text {
                                    text: root.artist
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 16
                                    color: Services.Theme.subtext
                                    visible: artistText.implicitWidth > artistRow.parent.width
                                }
                                
                                NumberAnimation on x {
                                    running: artistText.implicitWidth > artistRow.parent.width
                                    from: 0
                                    to: -(artistText.implicitWidth + 40)
                                    duration: (artistText.implicitWidth + 40) * 25
                                    loops: Animation.Infinite
                                }
                                
                                Connections {
                                    target: root
                                    function onArtistChanged() { artistRow.x = 0 }
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        id: appSwitcherPill
                        height: 28
                        width: Math.max(110, appSwitcherText.implicitWidth + 40)
                        radius: 14
                        color: pillMouse.containsMouse ? Services.Theme.highlight : Services.Theme.bgSolid
                        border.color: Services.Theme.border
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: {
                                    let c = Services.Mpris.currentPlayer.toLowerCase()
                                    if (c.includes("spotify")) return ""
                                    if (c.includes("feishin")) return "󰎆"
                                    if (c.includes("mpv")) return ""
                                    if (c.includes("vlc")) return "󰕼"
                                    if (c.includes("firefox") || c.includes("librewolf")) return ""
                                    return ""
                                }
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: {
                                    let c = Services.Mpris.currentPlayer.toLowerCase()
                                    if (c.includes("spotify")) return "#1DB954"
                                    return Services.Theme.text
                                }
                            }
                            Text {
                                id: appSwitcherText
                                text: Services.Mpris.currentPlayer !== "" ? (Services.Mpris.currentPlayer.charAt(0).toUpperCase() + Services.Mpris.currentPlayer.slice(1).split('.')[0]) : "No Player"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                font.weight: 600
                                color: Services.Theme.text
                            }
                        }
                        
                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                appMenu.visible = !appMenu.visible
                            }
                        }
                        
                        Rectangle {
                            id: appMenu
                            visible: false
                            y: appSwitcherPill.height + 4
                            width: Math.max(120, parent.width)
                            height: contentCol.implicitHeight + 8
                            radius: 12
                            color: Services.Theme.bgSolid
                            border.color: Services.Theme.border
                            border.width: 1
                            z: 100
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowOpacity: 0.3
                                shadowBlur: 10
                            }

                            ColumnLayout {
                                id: contentCol
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2
                                
                                Repeater {
                                    model: Services.Mpris.availablePlayers
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: 8
                                        color: delMouse.containsMouse ? Services.Theme.highlight : "transparent"
                                        
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1).split('.')[0]
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 12
                                            color: Services.Theme.text
                                        }
                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (Services.Mpris.currentPlayer !== modelData && Services.Mpris.currentPlayer !== "") {
                                                    Services.Mpris.pauseCurrent()
                                                }
                                                Services.Mpris.currentPlayer = modelData
                                                appMenu.visible = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Progress Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Layout.topMargin: 12

                    Rectangle {
                        id: progressBarArea
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Services.Theme.border
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10 // larger hit area
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (Services.Mpris.lengthSec > 0) {
                                    // Calculate relative click position ignoring the expanded margins
                                    var relativeX = Math.max(0, Math.min(mouse.x - 10, progressBarArea.width));
                                    var newPos = (relativeX / progressBarArea.width) * Services.Mpris.lengthSec;
                                    seekProc.command = Services.Mpris.playerArgs.concat(["position", newPos.toString()]);
                                    seekProc.running = true;
                                }
                            }
                        }

                        Rectangle {
                            height: parent.height
                            radius: 3
                            width: Services.Mpris.lengthSec > 0 ? parent.width * (Services.Mpris.positionSec / Services.Mpris.lengthSec) : 0
                            
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.lighter(Services.Theme.primary, 1.3) }
                                GradientStop { position: 1.0; color: Services.Theme.primary }
                            }
                            
                            Behavior on width { NumberAnimation { duration: 1000 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Services.Mpris.formatTime(Services.Mpris.positionSec)
                            color: Services.Theme.subtext
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Services.Mpris.formatTime(Services.Mpris.lengthSec)
                            color: Services.Theme.subtext
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24
                    Layout.topMargin: 8

                    Process { id: prevProc; command: Services.Mpris.playerArgs.concat(["previous"]) }
                    Process { id: nextProc; command: Services.Mpris.playerArgs.concat(["next"]) }
                    Process { id: seekProc; }

                    // Shuffle Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: shuffleMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        border.color: Services.Theme.border
                        border.width: root.shuffleMode ? 1 : 0
                        Text { 
                            anchors.centerIn: parent
                            text: "󰒎"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: root.shuffleMode ? Services.Theme.primary : Services.Theme.text
                            opacity: root.shuffleMode ? 1.0 : 0.45
                        }
                        MouseArea { id: shuffleMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleShuffle() }
                    }

                    // Previous Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: prevMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { anchors.centerIn: parent; text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; color: Services.Theme.text }
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { prevProc.running = false; prevProc.running = true } }
                    }

                    // Play/Pause Button
                    Rectangle {
                        width: 64; height: 64; radius: 32
                        color: playMouse.containsMouse ? Qt.darker(Services.Theme.primary, 1.1) : Services.Theme.primary
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Services.Theme.primary
                            shadowOpacity: Services.Mpris.playbackStatus === "Playing" ? 0.6 : 0.0
                            shadowBlur: 24
                            Behavior on shadowOpacity { NumberAnimation { duration: 500 } }
                        }

                        Text { 
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: Services.Mpris.playbackStatus === "Playing" ? 0 : 3
                            text: Services.Mpris.playbackStatus === "Playing" ? "󰏤" : "󰐊" 
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                            color: Services.Theme.bgSolid
                        }
                        MouseArea { 
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Services.Mpris.playPause()
                            scale: pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: nextMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { anchors.centerIn: parent; text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; color: Services.Theme.text }
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { nextProc.running = false; nextProc.running = true } }
                    }

                    // Loop Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: loopMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        border.color: Services.Theme.border
                        border.width: root.loopMode !== "None" ? 1 : 0
                        Text { 
                            anchors.centerIn: parent
                            text: root.loopMode === "Track" ? "󰑘" : "󰑖"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: root.loopMode !== "None" ? Services.Theme.primary : Services.Theme.text
                            opacity: root.loopMode !== "None" ? 1.0 : 0.45
                        }
                        MouseArea { id: loopMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleLoop() }
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
            }
        }
    }
}
