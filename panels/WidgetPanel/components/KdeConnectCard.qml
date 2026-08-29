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

    function getBatteryIcon(pct, charging) {
        if (charging) return "󰂄"
        if (pct >= 95) return "󰁹"
        if (pct >= 85) return "󰂂"
        if (pct >= 75) return "󰂀"
        if (pct >= 65) return "󰁿"
        if (pct >= 55) return "󰁾"
        if (pct >= 45) return "󰁽"
        if (pct >= 35) return "󰁼"
        if (pct >= 25) return "󰁻"
        if (pct >= 15) return "󰁺"
        return "󰂎"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        // Header: Phone Name & Status
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "📱"
                font.pixelSize: 14
            }

            Text {
                text: Services.KdeConnectService.deviceName
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.weight: 700
                color: Services.Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Connection Status Dot
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Services.KdeConnectService.connected ? "#a6e3a1" : Services.Theme.subtext
            }

            // Refresh Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: kdeRefMouse.containsMouse ? Services.Theme.highlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Services.KdeConnectService.loading ? Services.Theme.primary : Services.Theme.subtext

                    RotationAnimation on rotation {
                        running: Services.KdeConnectService.loading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: kdeRefMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Services.KdeConnectService.refresh()
                }
            }
        }

        // Hero Battery Display
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            spacing: 12

            Text {
                text: Services.KdeConnectService.connected ? root.getBatteryIcon(Services.KdeConnectService.batteryPercent, Services.KdeConnectService.isCharging) : "󰂎"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 36
                color: Services.KdeConnectService.connected ? Services.Theme.primary : Services.Theme.subtext
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Text {
                    text: Services.KdeConnectService.connected && Services.KdeConnectService.batteryPercent >= 0 ? Services.KdeConnectService.batteryPercent + "%" : (Services.KdeConnectService.connected ? "Connected" : "Offline")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 22
                    font.weight: 800
                    color: Services.Theme.text
                }

                Text {
                    text: Services.KdeConnectService.connected ? (Services.KdeConnectService.isCharging ? "⚡ Charging" : "🔋 Discharging") : "Pair via KDE Connect"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: 600
                    color: Services.Theme.subtext
                }
            }
        }

        // Divider Line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Services.Theme.border
            Layout.topMargin: 1
            Layout.bottomMargin: 1
        }

        // Action Buttons Grid (2x2)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            // Row 1: Ring & Ping
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Ring Phone
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: ringMouse.containsMouse ? Services.Theme.highlight : Qt.alpha(Services.Theme.bgSolid, 0.6)
                    border.color: Services.KdeConnectService.connected ? Qt.alpha(Services.Theme.primary, 0.4) : Qt.alpha(Services.Theme.border, 0.5)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text { text: "🔔"; font.pixelSize: 11 }
                        Text {
                            text: "Ring Phone"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: 700
                            color: Services.KdeConnectService.connected ? Services.Theme.text : Services.Theme.subtext
                        }
                    }

                    MouseArea {
                        id: ringMouse
                        anchors.fill: parent
                        cursorShape: Services.KdeConnectService.connected ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        hoverEnabled: true
                        onClicked: if (Services.KdeConnectService.connected) Services.KdeConnectService.ringPhone()
                    }
                }

                // Send Ping
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: pingMouse.containsMouse ? Services.Theme.highlight : Qt.alpha(Services.Theme.bgSolid, 0.6)
                    border.color: Services.KdeConnectService.connected ? Qt.alpha(Services.Theme.primary, 0.4) : Qt.alpha(Services.Theme.border, 0.5)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text { text: "󰂜"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: Services.Theme.primary }
                        Text {
                            text: "Ping"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: 700
                            color: Services.KdeConnectService.connected ? Services.Theme.text : Services.Theme.subtext
                        }
                    }

                    MouseArea {
                        id: pingMouse
                        anchors.fill: parent
                        cursorShape: Services.KdeConnectService.connected ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        hoverEnabled: true
                        onClicked: if (Services.KdeConnectService.connected) Services.KdeConnectService.pingPhone()
                    }
                }
            }

            // Row 2: Share Clipboard & Share Media
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Share Clipboard
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: clipMouse.containsMouse ? Services.Theme.highlight : Qt.alpha(Services.Theme.bgSolid, 0.6)
                    border.color: Services.KdeConnectService.connected ? Qt.alpha(Services.Theme.primary, 0.4) : Qt.alpha(Services.Theme.border, 0.5)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text { text: "📋"; font.pixelSize: 11 }
                        Text {
                            text: "Clipboard"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: 700
                            color: Services.KdeConnectService.connected ? Services.Theme.text : Services.Theme.subtext
                        }
                    }

                    MouseArea {
                        id: clipMouse
                        anchors.fill: parent
                        cursorShape: Services.KdeConnectService.connected ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        hoverEnabled: true
                        onClicked: if (Services.KdeConnectService.connected) Services.KdeConnectService.shareClipboard()
                    }
                }

                // Share Media
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: mediaMouse.containsMouse ? Services.Theme.highlight : Qt.alpha(Services.Theme.bgSolid, 0.6)
                    border.color: Services.KdeConnectService.connected ? Qt.alpha(Services.Theme.primary, 0.4) : Qt.alpha(Services.Theme.border, 0.5)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text { text: "📁"; font.pixelSize: 11 }
                        Text {
                            text: "Send File"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: 700
                            color: Services.KdeConnectService.connected ? Services.Theme.text : Services.Theme.subtext
                        }
                    }

                    MouseArea {
                        id: mediaMouse
                        anchors.fill: parent
                        cursorShape: Services.KdeConnectService.connected ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        hoverEnabled: true
                        onClicked: if (Services.KdeConnectService.connected) Services.KdeConnectService.shareMedia()
                    }
                }
            }
        }
    }
}
