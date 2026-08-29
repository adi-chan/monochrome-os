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

    property bool presenceActive: false

    Process {
        id: presenceCheckProc
        command: ["pgrep", "-f", "musicpresence"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.presenceActive = text.trim().length > 0
            }
        }
    }

    Process {
        id: presenceStartProc
        command: ["bash", "-c", "$HOME/tools/musicpresence-2.3.6-linux-x86_64.AppImage &"]
        onExited: {
            presenceCheckProc.running = false
            presenceCheckProc.running = true
        }
    }

    Process {
        id: presenceStopProc
        command: ["pkill", "-f", "musicpresence"]
        onExited: {
            presenceCheckProc.running = false
            presenceCheckProc.running = true
        }
    }

    Timer {
        id: presenceCheckTimer
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            presenceCheckProc.running = false
            presenceCheckProc.running = true
        }
    }



    MediaQueuePopup {
        id: mediaQueuePopup
        onPlaylistLoaded: root.shuffleMode = false
    }

    Component.onCompleted: {
    }

    Process {
        id: shuffleSetProc
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
        shuffleSetProc.command = ["bash", "-c", "mpc random off; mpc shuffle"]
        shuffleSetProc.running = false
        shuffleSetProc.running = true
        root.shuffleMode = true
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
                    source: root.artUrl !== "" ? root.artUrl : Qt.resolvedUrl("../../assets/music_fallback.svg")
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
                    
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter
                        z: 1000



                        // Discord / Music Presence Toggle Button
                        Rectangle {
                            id: presencePill
                            height: 28
                            width: 36
                            radius: 14
                            color: presenceMouse.containsMouse ? Services.Theme.highlight : (root.presenceActive ? Qt.alpha(Services.Theme.primary, 0.2) : Services.Theme.bgSolid)
                            border.color: root.presenceActive ? Services.Theme.primary : Services.Theme.border
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "󰙯"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: root.presenceActive ? Services.Theme.primary : Services.Theme.subtext
                            }
                            
                            MouseArea {
                                id: presenceMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (root.presenceActive) {
                                        presenceStopProc.running = false
                                        presenceStopProc.running = true
                                    } else {
                                        presenceStartProc.running = false
                                        presenceStartProc.running = true
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
                            text: ""
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: root.shuffleMode ? Services.Theme.primary : Services.Theme.text
                            opacity: root.shuffleMode ? 1.0 : 0.45
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea { id: shuffleMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleShuffle() }
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
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea { id: loopMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.cycleLoop() }
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

                    // Queue Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: queueMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { 
                            anchors.centerIn: parent
                            text: "󰲹"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: (mediaQueuePopup.visible && mediaQueuePopup.showingQueue) ? Services.Theme.primary : Services.Theme.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea { 
                            id: queueMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (mediaQueuePopup.visible && mediaQueuePopup.showingQueue) {
                                    mediaQueuePopup.visible = false
                                } else {
                                    mediaQueuePopup.showQueue()
                                }
                            }
                        }
                    }

                    // Library Button
                    Rectangle {
                        width: 48; height: 48; radius: 24
                        color: libMouse.containsMouse ? Services.Theme.highlight : "transparent"
                        Text { 
                            anchors.centerIn: parent
                            text: "󰕮"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: (mediaQueuePopup.visible && !mediaQueuePopup.showingQueue) ? Services.Theme.primary : Services.Theme.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea { 
                            id: libMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (mediaQueuePopup.visible && !mediaQueuePopup.showingQueue) {
                                    mediaQueuePopup.visible = false
                                } else {
                                    mediaQueuePopup.showLibrary()
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true } // Spacer
            }
        }

    // Overlays extracted to MediaQueuePopup
    }
}
