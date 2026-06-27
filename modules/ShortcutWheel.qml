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
    property var wheelApps: []
    property int selectedIndex: -1
    property bool isEditing: false

    onSelectedIndexChanged: {
        if (pop.open && selectedIndex !== -1) {
            selectSound.running = false;
            selectSound.running = true;
        }
    }

    color: "transparent"
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: pop.open || (mainWheel && mainWheel.opacity > 0.01)

    Process {
        id: loadApps
        command: ["cat", "/home/nick/.config/quickshell/assets/wheel.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    pop.wheelApps = JSON.parse(text)
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: loadApps.running = true

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (!pollProc.running) {
                pollProc.running = true;
            }
        }
    }

    Process {
        id: pollProc
        command: ["bash", "-c", "if [ -f /tmp/qs_wheel_open ]; then echo 1; else echo 0; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out !== "1" && out !== "0") return; // Ignore aborted processes
                
                let isOpen = out === "1";
                if (isOpen && !pop.open) {
                    pop.open = true;
                    pop.selectedIndex = -1;
                    loadApps.running = false;
                    loadApps.running = true;
                    openSound.running = false;
                    openSound.running = true;
                } else if (!isOpen && pop.open) {
                    pop.open = false;
                    if (pop.selectedIndex >= 0 && pop.selectedIndex < pop.wheelApps.length) {
                        if (pop.isEditing) {
                            editSlotProc.command = ["bash", "-c", "echo " + pop.selectedIndex + " > /tmp/qs_edit_slot && touch /tmp/qs_toggle_launcher"];
                            editSlotProc.running = true;
                        } else {
                            launchProc.command = ["hyprctl", "dispatch", "exec", pop.wheelApps[pop.selectedIndex].exec];
                            launchProc.running = true;
                        }
                    }
                    pop.isEditing = false;
                    editHoverTimer.stop();
                }
            }
        }
    }

    Timer {
        id: editHoverTimer
        interval: 1000
        onTriggered: {
            if (pop.selectedIndex === -1) {
                pop.isEditing = !pop.isEditing;
                selectSound.running = false;
                selectSound.running = true;
            }
        }
    }

    Process {
        id: forceCloseProc
        command: ["rm", "-f", "/tmp/qs_wheel_open"]
        running: false
    }

    Process {
        id: launchProc
        running: false
    }

    Process {
        id: editSlotProc
        running: false
    }

    Process {
        id: openSound
        command: ["pw-play", "/home/nick/.config/quickshell/assets/wheel_open.mp3"]
        running: false
    }
    
    Process {
        id: selectSound
        command: ["pw-play", "/home/nick/.config/quickshell/assets/wheel_select.mp3"]
        running: false
    }

    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        enabled: pop.open
        onPositionChanged: (mouse) => {
            if (!pop.open) return;
            
            let centerX = width / 2;
            let centerY = height / 2;
            let dx = mouse.x - centerX;
            let dy = mouse.y - centerY;
            
            let dist = Math.sqrt(dx*dx + dy*dy);
            if (dist < 40) {
                if (pop.selectedIndex !== -1) {
                    pop.selectedIndex = -1;
                    editHoverTimer.restart();
                }
                return;
            }
            
            editHoverTimer.stop();
            
            let angle = Math.atan2(dy, dx) * 180 / Math.PI;
            angle = (angle + 90 + 360) % 360;
            
            let index = Math.round(angle / 45) % 8;
            pop.selectedIndex = index;
        }
        
        onClicked: (mouse) => {
            let centerX = width / 2;
            let centerY = height / 2;
            let dx = mouse.x - centerX;
            let dy = mouse.y - centerY;
            let dist = Math.sqrt(dx*dx + dy*dy);
            
            if (dist > 150) {
                // Clicked outside the wheel - force close it
                forceCloseProc.running = true;
                return;
            }

            // Failsafe: if stuck open, clicking an app launches it.
            if (pop.selectedIndex >= 0 && pop.selectedIndex < pop.wheelApps.length) {
                launchProc.command = ["hyprctl", "dispatch", "exec", pop.wheelApps[pop.selectedIndex].exec];
                launchProc.running = true;
            }
            forceCloseProc.running = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent" // Remove full screen dimming

        Rectangle {
            id: mainWheel
            anchors.centerIn: parent
            width: 500
            height: 500
            radius: 250
            color: "#99000000" // Translucent dark background (blurs in Hyprland)
            border.color: "#30ffffff"
            border.width: 1
            
            scale: pop.open ? 1.0 : 0.85
            opacity: pop.open ? 1.0 : 0.0
            
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // Inner circle for aesthetics
            Rectangle {
                anchors.centerIn: parent
                width: 180
                height: 180
                radius: 90
                color: "transparent"
                border.color: "#40ffffff"
                border.width: 1
            }

    // Dividers
            Canvas {
                anchors.fill: parent
                anchors.margins: -40
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.lineWidth = 1.5;
                    
                    var cx = width / 2;
                    var cy = height / 2;
                    
                    // Create a fading gradient from the inner circle to the outer tip
                    var grad = ctx.createRadialGradient(cx, cy, 90, cx, cy, 280);
                    grad.addColorStop(0, "#40ffffff");
                    grad.addColorStop(0.7, "#40ffffff");
                    grad.addColorStop(1, "transparent");
                    ctx.strokeStyle = grad;
                    
                    for (var i = 0; i < 8; i++) {
                        var angle = (i * 45 - 90 + 22.5) * Math.PI / 180;
                        ctx.beginPath();
                        ctx.moveTo(cx + Math.cos(angle) * 90, cy + Math.sin(angle) * 90);
                        ctx.lineTo(cx + Math.cos(angle) * 280, cy + Math.sin(angle) * 280);
                        ctx.stroke();
                    }
                }
            }

            property real targetHighlightRotation: 0

            Connections {
                target: pop
                function onSelectedIndexChanged() {
                    if (pop.selectedIndex !== -1) {
                        mainWheel.targetHighlightRotation = pop.selectedIndex * 45;
                    }
                }
            }

            Canvas {
                id: highlightCanvas
                anchors.fill: parent
                
                opacity: pop.selectedIndex === -1 ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                rotation: mainWheel.targetHighlightRotation
                Behavior on rotation {
                    RotationAnimation { 
                        duration: 150 
                        direction: RotationAnimation.Shortest 
                        easing.type: Easing.OutCubic 
                    }
                }

                Component.onCompleted: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Draw a single wedge at the top (index 0 position)
                    // It will be rotated automatically by the rotation property
                    var startAngle = -90 * Math.PI / 180 - (22.5 * Math.PI / 180);
                    var endAngle = -90 * Math.PI / 180 + (22.5 * Math.PI / 180);
                    
                    var cx = width / 2;
                    var cy = height / 2;
                    var innerRadius = 90;
                    var outerRadius = width / 2;
                    
                    ctx.beginPath();
                    ctx.arc(cx, cy, innerRadius, startAngle, endAngle, false);
                    ctx.arc(cx, cy, outerRadius, endAngle, startAngle, true);
                    ctx.closePath();
                    
                    var grad = ctx.createRadialGradient(cx, cy, innerRadius, cx, cy, outerRadius);
                    grad.addColorStop(0, "#10ffffff");
                    grad.addColorStop(1, "#30ffffff");
                    ctx.fillStyle = grad;
                    ctx.fill();
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 60
                height: 60
                radius: 30
                color: pop.selectedIndex === -1 ? (pop.isEditing ? "#90ff3333" : "#60ffffff") : "transparent"
                border.color: pop.isEditing ? "#ff3333" : "#80ffffff"
                border.width: pop.isEditing ? 2 : 1
                
                scale: pop.selectedIndex === -1 ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: pop.isEditing ? "✖" : "✛" // Center crosshair icon
                    color: "#ffffff"
                    font.pixelSize: 24
                    opacity: 0.8
                    rotation: pop.isEditing ? 90 : 0
                    Behavior on rotation { RotationAnimation { duration: 250; easing.type: Easing.OutBack } }
                }
            }

            Repeater {
                model: pop.wheelApps
                delegate: Rectangle {
                    width: 90
                    height: 90
                    radius: 45
                    
                    scale: pop.selectedIndex === index ? 1.25 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    
                    property real angle: (index * 45 - 90) * Math.PI / 180
                    property real distance: 175
                    
                    // Center in the parent circle
                    x: 250 + Math.cos(angle) * distance - width / 2
                    y: 250 + Math.sin(angle) * distance - height / 2
                    
                    color: "transparent"
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 32
                            height: 32
                            color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon && modelData.icon.match(/[^\x00-\x7F]/) ? modelData.icon : (modelData.name ? modelData.name.charAt(0) : "?")
                                color: pop.selectedIndex === index ? "#000000" : "#ffffff"
                                font.pixelSize: 20
                                font.bold: true
                                visible: appIcon.status === Image.Error || appIcon.status === Image.Null || !modelData.icon || (modelData.icon && modelData.icon.match(/[^\x00-\x7F]/))
                            }

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                sourceSize: Qt.size(128, 128)
                                mipmap: true
                                source: modelData.icon && !modelData.icon.match(/[^\x00-\x7F]/) ? (modelData.icon.startsWith("/") ? "file://" + modelData.icon : "image://icon/" + modelData.icon) : ""
                                visible: status === Image.Ready && modelData.icon && !modelData.icon.match(/[^\x00-\x7F]/)
                            }
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name || ""
                            color: pop.selectedIndex === index ? "#000000" : "#ffffff"
                            font.pixelSize: 13
                            font.bold: true
                            width: 80
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
