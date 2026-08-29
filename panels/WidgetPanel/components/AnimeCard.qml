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

        // Header: Title & Refresh Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "📺"
                font.pixelSize: 14
            }

            Text {
                text: "Anime Release Countdown"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.weight: 700
                color: Services.Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: animeRefMouse.containsMouse ? Services.Theme.highlight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Services.AnimeService.loading ? Services.Theme.primary : Services.Theme.subtext

                    RotationAnimation on rotation {
                        running: Services.AnimeService.loading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: animeRefMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Services.AnimeService.refresh()
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

        // Anime Countdown List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: Services.AnimeService.animeList
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 10
                        color: Qt.alpha(Services.Theme.bgSolid, 0.6)
                        border.color: Qt.alpha(Services.Theme.border, 0.5)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            // Play Indicator
                            Text {
                                text: "󰐊"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: Services.Theme.primary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Title & Episode Info Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    text: modelData.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    font.weight: 700
                                    color: Services.Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.ep
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    color: Services.Theme.subtext
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Countdown Pill Badge
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                height: 20
                                width: countText.implicitWidth + 12
                                radius: 10
                                color: Qt.alpha(Services.Theme.primary, 0.15)
                                border.color: Qt.alpha(Services.Theme.primary, 0.4)
                                border.width: 1

                                Text {
                                    id: countText
                                    anchors.centerIn: parent
                                    text: modelData.countdown
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    font.weight: 700
                                    color: Services.Theme.primary
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: Services.AnimeService.animeList.length === 0
                    text: Services.AnimeService.loading ? "Loading countdowns..." : "No upcoming releases found"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: Services.Theme.subtext
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 30
                }
            }
        }
    }
}
