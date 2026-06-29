import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.modules.controlpanel
import qs.services as Services

PanelWindow {
    id: root
    
    anchors {
        bottom: true
        // Center the panel!
        // We anchor it to the horizontal center so it grows outward, 
        // OR we can just let it spawn at bottom-center if that's configured elsewhere.
        // Actually, if we want it to slide to the right (drawer), it's better to just stick to a fixed anchor or let Wayland handle it.
        // Let's add horizontalCenter anchor if we want it centered, but if it expands, it will grow evenly on both sides.
        // Let's just not set horizontalCenter to allow it to grow to the right from its origin!
    }
    
    margins {
        bottom: 0
    }
    
    color: "transparent"
    exclusiveZone: -1 // Overlay, do not push windows
    
    property int edgeZoneHeight: 10
    property int panelWidth: 380
    
    // Drawer settings
    property int appsWidth: 340
    property int sideGap: 12
    property bool showApps: false
    
    property bool expanded: false
    property bool pinExpanded: false
    
    // Fixed compact height for just Volume and Brightness
    property int targetHeight: 220
    
    // Timer to keep Wayland surface large while drawer closes
    Timer { id: appShrinkTimer; interval: 400 }
    
    // Horizontal size calculation
    property bool windowLargeW: showApps || appShrinkTimer.running
    implicitWidth: windowLargeW ? (panelWidth + appsWidth + sideGap) : panelWidth
    
    // Visual animated width
    property int visualWidth: showApps ? (panelWidth + appsWidth + sideGap) : panelWidth
    Behavior on visualWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    
    
    // Vertical size calculation
    property bool windowLarge: expanded || pinExpanded || closeAnimTimer.running
    implicitHeight: windowLarge ? targetHeight : edgeZoneHeight
    // Notice: NO Behavior on implicitHeight, so it snaps instantly, which is safer for Wayland surfaces!
    
    // Slide animation (slides up from the bottom)
    property real animY: (expanded || pinExpanded) ? 0 : targetHeight
    Behavior on animY { 
        NumberAnimation { 
            // 400ms duration with OutExpo creates a very silky smooth, fluid deceleration
            duration: 400 
            easing.type: (root.expanded || root.pinExpanded) ? Easing.OutExpo : Easing.InExpo
        } 
    }
    
    // Root hover detection
    HoverHandler {
        id: rootHover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                closeAnimTimer.stop()
                root.expanded = true
            } else {
                hideTimer.restart()
            }
        }
    }
    
    Timer {
        id: hideTimer
        interval: 250
        onTriggered: {
            if (!root.pinExpanded && !rootHover.hovered) {
                root.expanded = false
                root.showApps = false // close drawer when panel closes
                closeAnimTimer.restart()
            }
        }
    }
    
    Timer {
        id: closeAnimTimer
        interval: 400 // matches the animY duration
    }
    
    // The panel container (Animates its width and Y)
    Item {
        width: root.visualWidth
        height: root.targetHeight
        
        // Slide from bottom to top
        y: root.animY
        
        // Fade in smoothly as it slides
        opacity: (root.expanded || root.pinExpanded) ? 1 : 0
        Behavior on opacity { 
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad } 
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: root.sideGap
            
            // Left Panel (Main Controls)
            Rectangle {
                Layout.preferredWidth: root.panelWidth
                Layout.fillHeight: true
                radius: 16
                color: Services.Theme.bg
                border.color: Services.Theme.border
                border.width: 1
                
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.28
                    shadowBlur: 0.55
                    shadowVerticalOffset: 5
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Audio & Brightness"
                            color: Services.Theme.text
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: root.pinExpanded ? "#b4befe" : "#413b3b"
                            Text {
                                anchors.centerIn: parent
                                text: "󰐃"
                                color: root.pinExpanded ? "#000000" : "#ffffff"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinExpanded = !root.pinExpanded
                            }
                        }
                    }
                    
                    Rectangle { Layout.fillWidth: true; height: 1; color: Services.Theme.border }
                    
                    // Master Volume
                    Loader {
                        id: volLoader
                        Layout.fillWidth: true
                        source: "controlpanel/Volume.qml"
                    }
                    
                    Connections {
                        target: volLoader.item
                        ignoreUnknownSignals: true
                        function onSidePanelRequested() {
                            if (!root.showApps) {
                                root.showApps = true;
                                appShrinkTimer.stop();
                            } else {
                                root.showApps = false;
                                appShrinkTimer.restart();
                            }
                        }
                    }
                    
                    // Brightness
                    Loader {
                        Layout.fillWidth: true
                        source: "controlpanel/Brightness.qml"
                    }
                }
            }
            
            // Right Panel (App Mixer Drawer)
            AppMixerDrawer {
                Layout.preferredWidth: root.appsWidth
                Layout.fillHeight: true
                // We clip it or fade it so it looks good during slide
                visible: root.visualWidth > (root.panelWidth + 10)
                opacity: root.showApps ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.28
                    shadowBlur: 0.55
                    shadowVerticalOffset: 5
                }
            }
        }
    }
}
