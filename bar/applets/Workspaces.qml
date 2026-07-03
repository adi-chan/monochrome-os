import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services as Services
import qs.panels.RightPanel
import qs.panels.WidgetPanel
import qs.panels.Power
import qs.panels.Launchers
import qs.panels.Notifications
import qs.panels.Media
import qs.panels.OSD

Item {
    id: root
    property int maxWorkspaces: 10

    // Sizes 
    property int sizeSmall: 20
    property int sizeMedium: 16
    property int sizeLarge: 30  // focused pill width

    readonly property var occupiedMap: Hyprland.workspaces.values.reduce(
        (acc, ws) => {
            const winCount = (ws.lastIpcObject && ws.lastIpcObject.windows) || 0
            acc[ws.id] = winCount > 0
            return acc
        },
        {}
    )

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    Rectangle {
        id: bg
        color: Services.Theme.bgSolid
        radius: height / 2
        anchors.centerIn: parent

        implicitWidth: row.implicitWidth + 16
        implicitHeight: row.implicitHeight + 16

        Rectangle {
            id: activeIndicator
            width: 24
            height: 24
            radius: 12
            color: Services.Theme.isDark ? "#ff0000" : "#d32f2f" // active red
            
            property int activeIdx: {
                if (Hyprland.focusedWorkspace) {
                    let idx = Hyprland.focusedWorkspace.id - 1;
                    if (idx >= 0 && idx < root.maxWorkspaces) return idx;
                }
                return 0;
            }
            
            // Wait for the repeater item to exist
            property var activeItem: wsRepeater.itemAt(activeIdx)
            
            x: row.x + (activeItem ? activeItem.x + activeItem.width / 2 - width / 2 : 0)
            y: (bg.height - height) / 2
            
            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
        }

        Row {
            id: row
            spacing: 12
            anchors.centerIn: parent

            Repeater {
                id: wsRepeater
                model: root.maxWorkspaces

                Rectangle {
                    id: wsBox
                    property int wid: index + 1

                    property bool isFocused:
                        Hyprland.focusedWorkspace
                        && Hyprland.focusedWorkspace.id === wid

                    property bool isOccupied: occupiedMap[wid] === true

                    property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
                    property string wsText: wid <= 10 ? kanji[wid - 1] : wid.toString()

                    width: 16
                    height: 16
                    radius: 8

                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: wsBox.wsText
                        color: wsBox.isFocused ? (Services.Theme.isDark ? "#ffffff" : "#000000") : (wsBox.isOccupied ? Services.Theme.text : "#808080")
                        font.pixelSize: 13
                        font.weight: Font.Black
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Services.Theme.bg
                        opacity: wsBox.hovered ? 0.18 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    SequentialAnimation {
                        id: bounceAnim
                        running: false
                        loops: 1

                        NumberAnimation { target: wsBox; property: "scale"; to: 1.20; duration: 120; easing.type: Easing.OutQuad }
                        NumberAnimation { target: wsBox; property: "scale"; to: 0.92; duration: 120; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: wsBox; property: "scale"; to: 1.0; duration: 130; easing.type: Easing.OutBounce }
                    }

                    Connections {
                        target: Hyprland
                        onFocusedWorkspaceChanged: {
                            if (wsBox.isFocused) {
                                wsBox.scale = 1
                                bounceAnim.start()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: wsBox.hovered = true
                        onExited: wsBox.hovered = false
                        onClicked: Hyprland.dispatch("workspace " + wsBox.wid)
                    }
                }
            }
        }
    }
}
