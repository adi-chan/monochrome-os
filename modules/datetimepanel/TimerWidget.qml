import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services as Services

Item {
    id: root

    property int hrVal: 0
    property int minVal: 0

    // Force canvas repaint on progress change
    Connections {
        target: Services.TimerService
        function onProgressChanged() {
            progressCanvas.requestPaint()
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 32

        // Left side: Circular Progress & Time
        Item {
            Layout.preferredWidth: 160
            Layout.preferredHeight: 160
            
            Canvas {
                id: progressCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = width / 2 - 8;
                    
                    // Background ring
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                    ctx.lineWidth = 8;
                    ctx.strokeStyle = Services.Theme.secondaryContainer;
                    ctx.stroke();
                    
                    // Progress ring
                    if (Services.TimerService.totalSeconds > 0) {
                        ctx.beginPath();
                        var startAngle = -Math.PI / 2;
                        var p = Services.TimerService.progress;
                        var endAngle = startAngle + (p * 2 * Math.PI);
                        
                        // To avoid weird drawing when progress is exactly 0
                        if (p > 0.001) {
                            ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                            ctx.lineWidth = 8;
                            ctx.strokeStyle = Services.Theme.primary; // Or a bright accent
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                font.family: "JetBrains Mono"
                font.pixelSize: 32
                font.weight: 700
                color: Services.Theme.text
                text: {
                    var total = Math.ceil(Services.TimerService.remainingSeconds);
                    if (total === 0 && !Services.TimerService.isRunning) {
                        total = root.hrVal * 3600 + root.minVal * 60;
                    }
                    var h = Math.floor(total / 3600);
                    var m = Math.floor((total % 3600) / 60);
                    var s = total % 60;
                    if (h > 0) {
                        return h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0');
                    } else {
                        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0');
                    }
                }
            }
        }

        // Right side: Controls
        ColumnLayout {
            spacing: 16

            RowLayout {
                spacing: 12

                // Hour Input
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 50
                    radius: 12
                    color: hrMouseArea.containsMouse ? Services.Theme.secondaryContainer : Services.Theme.bg
                    border.width: 1
                    border.color: Services.Theme.border
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        TextInput {
                            id: hrInput
                            text: root.hrVal.toString()
                            color: Services.Theme.text
                            font.pixelSize: 20
                            font.family: "JetBrains Mono"
                            font.weight: 600
                            validator: IntValidator { bottom: 0; top: 23 }
                            onActiveFocusChanged: if (activeFocus) selectAll()
                            onTextEdited: {
                                var v = parseInt(text) || 0
                                root.hrVal = v
                            }
                            onEditingFinished: {
                                text = Qt.binding(function() { return root.hrVal.toString() })
                            }
                        }
                        Text {
                            text: "h"
                            color: Services.Theme.subtext
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: hrMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: { hrInput.forceActiveFocus() }
                        onWheel: (wheel) => {
                            if (!Services.TimerService.isRunning) {
                                var v = root.hrVal + (wheel.angleDelta.y > 0 ? 1 : -1)
                                if (v < 0) v = 23;
                                if (v > 23) v = 0;
                                root.hrVal = v;
                            }
                        }
                    }
                }

                // Minute Input
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 50
                    radius: 12
                    color: minMouseArea.containsMouse ? Services.Theme.secondaryContainer : Services.Theme.bg
                    border.width: 1
                    border.color: Services.Theme.border
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        TextInput {
                            id: minInput
                            text: root.minVal.toString().padStart(2, '0')
                            color: Services.Theme.text
                            font.pixelSize: 20
                            font.family: "JetBrains Mono"
                            font.weight: 600
                            validator: IntValidator { bottom: 0; top: 59 }
                            onActiveFocusChanged: if (activeFocus) selectAll()
                            onTextEdited: {
                                var v = parseInt(text) || 0
                                root.minVal = v
                            }
                            onEditingFinished: {
                                text = Qt.binding(function() { return root.minVal.toString().padStart(2, '0') })
                            }
                        }
                        Text {
                            text: "m"
                            color: Services.Theme.subtext
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: minMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: { minInput.forceActiveFocus() }
                        onWheel: (wheel) => {
                            if (!Services.TimerService.isRunning) {
                                var v = root.minVal + (wheel.angleDelta.y > 0 ? 1 : -1)
                                if (v < 0) v = 59;
                                if (v > 59) v = 0;
                                root.minVal = v;
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 12

                // Start/Pause Button
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 44
                    radius: 10
                    color: Services.TimerService.isRunning ? Services.Theme.secondaryContainer : Services.Theme.primary
                    
                    Text {
                        anchors.centerIn: parent
                        text: Services.TimerService.isRunning ? "Pause" : "Start"
                        color: Services.TimerService.isRunning ? Services.Theme.text : Services.Theme.bg
                        font.pixelSize: 15
                        font.weight: 700
                        font.family: "JetBrains Mono"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Services.TimerService.isRunning) {
                                Services.TimerService.toggleTimer();
                            } else {
                                if (Services.TimerService.remainingSeconds > 0 && Services.TimerService.totalSeconds > 0) {
                                    Services.TimerService.toggleTimer();
                                } else {
                                    Services.TimerService.startTimer(root.hrVal, root.minVal);
                                }
                            }
                        }
                    }
                }

                // Reset Button
                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 44
                    radius: 10
                    color: Services.Theme.bg
                    border.width: 1
                    border.color: Services.Theme.border
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        color: Services.Theme.text
                        font.pixelSize: 15
                        font.weight: 600
                        font.family: "JetBrains Mono"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Services.TimerService.resetTimer();
                            Services.TimerService.remainingSeconds = 0;
                            Services.TimerService.totalSeconds = 0;
                        }
                    }
                }
            }
        }
    }
}
