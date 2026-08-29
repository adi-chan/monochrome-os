import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services as Services

Rectangle {
    id: root
    radius: 16
    color: Services.Theme.bg
    border.color: Services.Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header: Inspector Title & Current Workspace
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "󰖯"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: Services.Theme.primary
            }

            Text {
                text: "Hyprland Inspector"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.weight: 700
                color: Services.Theme.text
                Layout.fillWidth: true
            }

            Rectangle {
                height: 20
                width: wsText.implicitWidth + 12
                radius: 10
                color: Qt.alpha(Services.Theme.primary, 0.15)
                border.color: Qt.alpha(Services.Theme.primary, 0.4)
                border.width: 1

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: "WS " + Services.HyprInspectorService.workspaceId
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: 700
                    color: Services.Theme.primary
                }
            }
        }

        // Active App Banner
        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 12
            color: Qt.alpha(Services.Theme.bgSolid, 0.6)
            border.color: Qt.alpha(Services.Theme.border, 0.5)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    text: Services.HyprInspectorService.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 26
                    color: Services.Theme.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: Services.HyprInspectorService.windowTitle
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 700
                        color: Services.Theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Services.HyprInspectorService.windowClass
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: Services.Theme.subtext
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // App Details Badges: PID, Size, Window Mode
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // PID Badge
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: Qt.alpha(Services.Theme.bgSolid, 0.4)
                border.color: Qt.alpha(Services.Theme.border, 0.4)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰍛"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Services.Theme.subtext
                    }
                    Text {
                        text: Services.HyprInspectorService.pid > 0 ? "PID " + Services.HyprInspectorService.pid : "PID --"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: Services.Theme.subtext
                    }
                }
            }

            // Size / Mode Badge
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: Qt.alpha(Services.Theme.bgSolid, 0.4)
                border.color: Qt.alpha(Services.Theme.border, 0.4)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Services.HyprInspectorService.isFloating ? "󰈈" : "󰖲"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Services.Theme.subtext
                    }
                    Text {
                        text: Services.HyprInspectorService.winWidth > 0 ? (Services.HyprInspectorService.winWidth + "x" + Services.HyprInspectorService.winHeight) : (Services.HyprInspectorService.isFloating ? "Floating" : "Tiled")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: Services.Theme.subtext
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Services.Theme.border
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        // Active Workspaces Strip
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Workspaces:"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.weight: 600
                color: Services.Theme.subtext
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: Services.HyprInspectorService.activeWorkspaces
                    delegate: Rectangle {
                        height: 20
                        width: Math.max(24, wsName.implicitWidth + 10)
                        radius: 10
                        color: modelData.id === Services.HyprInspectorService.workspaceId ? Services.Theme.primary : Qt.alpha(Services.Theme.bgSolid, 0.6)
                        border.color: modelData.id === Services.HyprInspectorService.workspaceId ? Services.Theme.primary : Qt.alpha(Services.Theme.border, 0.5)
                        border.width: 1

                        Text {
                            id: wsName
                            anchors.centerIn: parent
                            text: modelData.name + (modelData.windows > 0 ? " (" + modelData.windows + ")" : "")
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.weight: modelData.id === Services.HyprInspectorService.workspaceId ? 700 : 500
                            color: modelData.id === Services.HyprInspectorService.workspaceId ? Services.Theme.bg : Services.Theme.text
                        }
                    }
                }
            }
        }
    }
}
