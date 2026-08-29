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

    property int activeTab: 0 // 0 = Anime, 1 = Themes

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header: Tab Bar Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 14
                color: root.activeTab === 0 ? Qt.alpha(Services.Theme.primary, 0.18) : Qt.alpha(Services.Theme.bgSolid, 0.4)
                border.color: root.activeTab === 0 ? Services.Theme.primary : Qt.alpha(Services.Theme.border, 0.5)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "📺"
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Anime"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: root.activeTab === 0 ? 700 : 500
                        color: root.activeTab === 0 ? Services.Theme.primary : Services.Theme.subtext
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeTab = 0
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 14
                color: root.activeTab === 1 ? Qt.alpha(Services.Theme.primary, 0.18) : Qt.alpha(Services.Theme.bgSolid, 0.4)
                border.color: root.activeTab === 1 ? Services.Theme.primary : Qt.alpha(Services.Theme.border, 0.5)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "🎨"
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Themes"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: root.activeTab === 1 ? 700 : 500
                        color: root.activeTab === 1 ? Services.Theme.primary : Services.Theme.subtext
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeTab = 1
                }
            }
        }

        // Content Stack
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTab

            // TAB 0: ANIME SCHEDULE
            ColumnLayout {
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: Services.AnimeService.currentDay + " Releases"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: 700
                        color: Services.Theme.text
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: animeRefMouse.containsMouse ? Services.Theme.highlight : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
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

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: Services.AnimeService.animeList
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: Qt.alpha(Services.Theme.bgSolid, 0.5)
                                border.color: Qt.alpha(Services.Theme.border, 0.4)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        text: "🍿"
                                        font.pixelSize: 12
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            text: modelData.title
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            font.weight: 600
                                            color: Services.Theme.text
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.ep + " • " + modelData.time + " JST"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 9
                                            color: Services.Theme.subtext
                                        }
                                    }

                                    Text {
                                        text: "★ " + modelData.score
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        font.weight: 700
                                        color: Services.Theme.primary
                                    }
                                }
                            }
                        }

                        Text {
                            visible: Services.AnimeService.animeList.length === 0
                            text: Services.AnimeService.loading ? "Fetching schedule..." : "No scheduled anime today"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: Services.Theme.subtext
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 20
                        }
                    }
                }
            }

            // TAB 1: THEME SWAPPER
            ColumnLayout {
                spacing: 6

                Text {
                    text: "Select Color Palette"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.weight: 700
                    color: Services.Theme.text
                }

                readonly property var themePresets: [
                    { name: "Monochrome", label: "Monochrome", color: "#ffffff", bg: "#0c0c0c" },
                    { name: "Catppuccin", label: "Catppuccin Mocha", color: "#cba6f7", bg: "#1e1e2e" },
                    { name: "Tokyonight", label: "Tokyo Night", color: "#7dcfff", bg: "#1a1b26" },
                    { name: "Nord", label: "Nord Frost", color: "#88c0d0", bg: "#2e3440" },
                    { name: "RosePine", label: "Rosé Pine", color: "#ebbcba", bg: "#191724" }
                ]

                Repeater {
                    model: parent.themePresets
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: Services.Theme.activePreset === modelData.name ? Qt.alpha(Services.Theme.primary, 0.2) : Qt.alpha(Services.Theme.bgSolid, 0.5)
                        border.color: Services.Theme.activePreset === modelData.name ? Services.Theme.primary : Qt.alpha(Services.Theme.border, 0.5)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData.color
                                border.color: "#ffffff"
                                border.width: 1
                            }

                            Text {
                                text: modelData.label
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                font.weight: Services.Theme.activePreset === modelData.name ? 700 : 500
                                color: Services.Theme.activePreset === modelData.name ? Services.Theme.primary : Services.Theme.text
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: Services.Theme.activePreset === modelData.name
                                text: "✓"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                font.weight: 800
                                color: Services.Theme.primary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Theme.applyPreset(modelData.name)
                        }
                    }
                }
            }
        }
    }
}
