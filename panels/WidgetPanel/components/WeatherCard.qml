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

    property bool showLocation: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header: Location & Refresh Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 6
                color: locMouse.containsMouse ? Services.Theme.highlight : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 6

                    Text {
                        text: root.showLocation ? "󰍎" : "󰈈"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: root.showLocation ? Services.Theme.primary : Services.Theme.subtext
                    }

                    Text {
                        text: root.showLocation ? Services.WeatherService.city : "Location Hidden"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.weight: 700
                        color: root.showLocation ? Services.Theme.text : Services.Theme.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: locMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.showLocation = !root.showLocation
                }
            }

            // Refresh Icon Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: refreshMouse.containsMouse ? Services.Theme.highlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Services.WeatherService.loading ? Services.Theme.primary : Services.Theme.subtext
                    
                    RotationAnimation on rotation {
                        running: Services.WeatherService.loading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Services.WeatherService.refresh()
                }
            }
        }

        // Hero Weather Info: Icon & Main Temperature
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 12

            Text {
                text: Services.WeatherService.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 40
                color: Services.Theme.primary
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                RowLayout {
                    spacing: 6
                    Text {
                        text: Services.WeatherService.tempC
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24
                        font.weight: 800
                        color: Services.Theme.text
                    }
                    Text {
                        text: "(" + Services.WeatherService.tempF + ")"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: Services.Theme.subtext
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 3
                    }
                }

                Text {
                    text: Services.WeatherService.condition
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.weight: 600
                    color: Services.Theme.subtext
                    elide: Text.ElideRight
                }
            }
        }

        // Extra details: Humidity & Wind
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            RowLayout {
                spacing: 4
                Text {
                    text: "󰖎"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Qt.alpha(Services.Theme.text, 0.6)
                }
                Text {
                    text: Services.WeatherService.humidity
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: Services.Theme.subtext
                }
            }

            RowLayout {
                spacing: 4
                Text {
                    text: "󰈐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Qt.alpha(Services.Theme.text, 0.6)
                }
                Text {
                    text: Services.WeatherService.windSpeed
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: Services.Theme.subtext
                }
            }
        }

        // Divider Line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Services.Theme.border
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        // 3-Day Forecast Section
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Services.WeatherService.forecast
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 10
                    color: Qt.alpha(Services.Theme.bgSolid, 0.6)
                    border.color: Qt.alpha(Services.Theme.border, 0.5)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: modelData.day
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: 700
                            color: Services.Theme.text
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: Services.Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: modelData.min + " - " + modelData.max
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: Services.Theme.subtext
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
