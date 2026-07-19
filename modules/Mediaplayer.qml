import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    implicitHeight: 28
    implicitWidth: 320
    Layout.preferredWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter

    // direct colors (replaced theme)
    property color bg: Services.Theme.bgSolid
    property color text: Services.Theme.text
    property color btnBg: Services.Theme.bg
    property color borderColor: Services.Theme.border

    // whole-module button feedback
    property color cardHover: "#2f3042"
    property color cardPress: "#2a2b3a"

    readonly property var mpris: Services.Mpris
    readonly property string line: (mpris.albumArtist || "No Artist") + " - " + (mpris.albumTitle || "No Media")

    property bool isPlaying: false
    
    property var audioData: new Array(80).fill(0)
    property int audioTick: 0
    Process {
        id: cavaProc
        running: root.isPlaying
        command: ["cava", "-p", "/home/nick/.config/quickshell/cava.conf"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";")
                let newArr = new Array(80)
                for (let i = 0; i < 80; i++) {
                    newArr[i] = parseInt(parts[i]) || 0
                }
                root.audioData = newArr
                root.audioTick++
            }
        }
    }
    property bool needsMarquee: false
    property int fadeW: 12
    property string playbackTime: ""

    property bool detailsOpen: false
    property var onOpen: function() { detailsOpen = !detailsOpen }

    Process { id: playPauseProc; command: ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "play-pause"] }
    Process { id: prevProc; command: ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "previous"] }
    Process { id: nextProc; command: ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera", "next"] }

    Process {
        id: statusProc
        command: ["bash", "-lc", "playerctl --ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera status 2>/dev/null || echo Stopped"]
        stdout: StdioCollector {
            onStreamFinished: root.isPlaying = (text.trim() === "Playing")
        }
    }

    Process {
        id: timeProc
        command: ["bash", "-c", "playerctl --ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera metadata --format '{{ duration(position) }}' 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = text.trim();
                // Filter out broken lengths like 16 hours
                if (t && !t.includes("16:")) {
                    root.playbackTime = t;
                } else {
                    root.playbackTime = "";
                }
            }
        }
    }

    Timer {
        interval: 800
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = false
            statusProc.running = true
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: {
            timeProc.running = false
            timeProc.running = true
        }
    }

        Canvas {
            id: eqCanvas
            anchors.fill: parent
            anchors.margins: -16
            visible: root.isPlaying
            z: -1
            
            Connections {
                target: root
                function onAudioTickChanged() {
                    eqCanvas.requestPaint();
                }
            }
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                var w = width - 32;
                var h = height - 32;
                var R = h / 2;
                
                function getPillPoint(t) {
                    var w_straight = Math.max(0, w - 2 * R);
                    var arc_len = Math.PI * R;
                    var total_len = 2 * w_straight + 2 * arc_len;
                    
                    var d = t * total_len;
                    
                    if (d <= w_straight) {
                        return { x: R + d, y: 0, nx: 0, ny: -1 };
                    }
                    d -= w_straight;
                    
                    if (d <= arc_len) {
                        var angle = -Math.PI/2 + (d / arc_len) * Math.PI;
                        return { x: w - R + Math.cos(angle) * R, y: R + Math.sin(angle) * R, nx: Math.cos(angle), ny: Math.sin(angle) };
                    }
                    d -= arc_len;
                    
                    if (d <= w_straight) {
                        return { x: w - R - d, y: h, nx: 0, ny: 1 };
                    }
                    d -= w_straight;
                    
                    var angle = Math.PI/2 + (d / arc_len) * Math.PI;
                    return { x: R + Math.cos(angle) * R, y: R + Math.sin(angle) * R, nx: Math.cos(angle), ny: Math.sin(angle) };
                }
                
                ctx.fillStyle = root.bg;
                ctx.beginPath();
                
                var points = 250;
                for (var i = 0; i <= points; i++) {
                    var t = i / points;
                    var pt = getPillPoint(t);
                    
                    var fIndex = (pt.x / w) * 79;
                    var idx1 = Math.floor(fIndex);
                    var idx2 = Math.min(79, idx1 + 1);
                    var frac = fIndex - idx1;
                    var val = (root.audioData[idx1] || 0) * (1 - frac) + (root.audioData[idx2] || 0) * frac;
                    
                    // Simple easing/smoothing to avoid sharp jumps
                    var h_offset = (val / 100) * 12;
                    
                    var cx = 16 + pt.x + pt.nx * h_offset;
                    var cy = 16 + pt.y + pt.ny * h_offset;
                    
                    if (i === 0) {
                        ctx.moveTo(cx, cy);
                    } else {
                        ctx.lineTo(cx, cy);
                    }
                }
                ctx.closePath();
                ctx.fill();
            }
        }

        Rectangle {
            id: card
        anchors.fill: parent
        radius: 14
        antialiasing: true
        transformOrigin: Item.Center

        scale: cardMouse.pressed ? 0.985 : (cardMouse.containsMouse ? 1.03 : 1.0)
        color: root.bg

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: cardMouse.containsMouse ? 0.35 : 0.0
            shadowBlur: 0.9
            shadowVerticalOffset: cardMouse.containsMouse ? 2 : 0
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 0
            onClicked: root.onOpen()
        }

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            anchors.leftMargin: 2
            anchors.rightMargin: 14
            spacing: 8
            z: 1

            Rectangle {
                id: controlPill
                Layout.preferredWidth: 86 + ((root.playbackTime !== "" && root.line !== "No Artist - No Media") ? 44 : 0)
                Layout.preferredHeight: 24
                radius: 12
                color: root.btnBg
                border.width: 1
                border.color: root.borderColor
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 0

                    // Prev
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            color: root.text
                            opacity: prevMouse.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                prevProc.running = false
                                prevProc.running = true
                            }
                        }
                    }

                    // Play/Pause
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "󰏤" : "󰐊"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                            color: root.text
                            opacity: 0.95
                            visible: !root.isPlaying || btnMouse.containsMouse
                        }

                        // Animated Equalizer inside the button
                        Row {
                            id: eqIcon
                            anchors.centerIn: parent
                            spacing: 2
                            visible: root.isPlaying && !btnMouse.containsMouse
                            height: 10
                            
                            Repeater {
                                model: 5
                                Rectangle {
                                    width: 3
                                    height: 4
                                    radius: 1
                                    color: root.text
                                    anchors.bottom: parent.bottom
                                    
                                    SequentialAnimation on height {
                                        running: root.isPlaying
                                        loops: Animation.Infinite
                                        
                                        NumberAnimation { 
                                            to: [10, 6, 12, 5, 8][index]
                                            duration: 200 + (index * 35)
                                            easing.type: Easing.InOutQuad 
                                        }
                                        NumberAnimation { 
                                            to: 3
                                            duration: 250 + (index * 25)
                                            easing.type: Easing.InOutQuad 
                                        }
                                        NumberAnimation { 
                                            to: [5, 10, 7, 11, 4][index]
                                            duration: 180 + (index * 30)
                                            easing.type: Easing.InOutQuad 
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                playPauseProc.running = false
                                playPauseProc.running = true
                                statusProc.running = false
                                statusProc.running = true
                            }
                        }
                    }

                    // Next
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            color: root.text
                            opacity: nextMouse.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            propagateComposedEvents: false
                            onClicked: {
                                nextProc.running = false
                                nextProc.running = true
                            }
                        }
                    }

                    // Time Text
                    Item {
                        Layout.preferredWidth: timeText.implicitWidth
                        Layout.fillHeight: true
                        visible: root.playbackTime !== "" && root.line !== "No Artist - No Media"
                        Layout.rightMargin: 6
                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: root.playbackTime
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.weight: 600
                            color: root.text
                            opacity: 0.8
                        }
                    }
                }
            }

            Item {
                id: viewport
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 20
                clip: true

                Row {
                    id: marqueeRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22
                    x: 0

                    Text {
                        id: textA
                        text: root.line
                        color: root.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 750
                        elide: Text.ElideNone
                    }

                    Text {
                        id: textB
                        text: textA.text
                        color: root.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 750
                        elide: Text.ElideNone
                        visible: root.needsMarquee
                    }
                }

                Item {
                    z: 10
                    visible: root.needsMarquee
                    width: root.fadeW
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: card.color }
                            GradientStop { position: 1.0; color: Qt.alpha(card.color, 0.0) }
                        }
                    }
                }

                Item {
                    z: 10
                    visible: root.needsMarquee
                    width: root.fadeW
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.alpha(card.color, 0.0) }
                            GradientStop { position: 1.0; color: card.color }
                        }
                    }
                }

                Timer {
                    id: marqueeDelay
                    interval: 1000
                    repeat: false
                    onTriggered: {
                        if (root.needsMarquee) marqueeAnim.start()
                    }
                }

                function recompute(resetPosition) {
                    const usable = Math.max(0, viewport.width - (root.fadeW * 2))
                    root.needsMarquee = textA.paintedWidth > usable

                    marqueeAnim.stop()
                    marqueeDelay.stop()

                    if (resetPosition || !root.needsMarquee) marqueeRow.x = 0

                    if (root.needsMarquee) {
                        marqueeAnim.from = 0
                        marqueeAnim.to = -(textA.paintedWidth + marqueeRow.spacing)
                        marqueeDelay.start()
                    }
                }

                onWidthChanged: recompute(false)
                Component.onCompleted: recompute(true)

                Connections {
                    target: root.mpris
                    function onAlbumArtistChanged() { viewport.recompute(true) }
                    function onAlbumTitleChanged()  { viewport.recompute(true) }
                }

                NumberAnimation {
                    id: marqueeAnim
                    target: marqueeRow
                    property: "x"
                    from: 0
                    to: -(textA.paintedWidth + marqueeRow.spacing)
                    duration: Math.max(12000, textA.paintedWidth * 22)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                    running: false
                }
            }
        }
    }

    MediaPopup {
        id: mediaPop
        open: root.detailsOpen
        anchorItem: root
        onRequestClose: root.detailsOpen = false
    }
}