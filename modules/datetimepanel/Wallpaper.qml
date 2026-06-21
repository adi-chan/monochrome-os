import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string wallpaperDir: "/home/nick/Backgrounds"
    property bool showPathInput: false

    Component.onCompleted: loadPathProc.running = true

    Process {
        id: loadPathProc
        command: ["bash", "-c", "cat ~/.config/quickshell/assets/wallpaper_path.txt 2>/dev/null || echo '/home/nick/Backgrounds'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim()
                if (p.length > 0) root.wallpaperDir = p
            }
        }
    }

    Process {
        id: savePathProc
        running: false
    }

    onWallpaperDirChanged: {
        savePathProc.running = false
        savePathProc.command = ["bash", "-c", "echo '" + root.wallpaperDir + "' > ~/.config/quickshell/assets/wallpaper_path.txt"]
        savePathProc.running = true
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png"]
        showDirs: false
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            spacing: 8

            Rectangle {
                width: 36; height: 36
                color: "#1e1e2e"
                radius: 6
                Text { anchors.centerIn: parent; text: "📁"; font.pixelSize: 18 }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPathInput = !root.showPathInput
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.showPathInput
                height: 36
                color: "#1e1e2e"
                radius: 6
                border.width: 1
                border.color: pathInput.activeFocus ? "#7aa2f7" : "#45475a"

                TextInput {
                    id: pathInput
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: Qt.AlignVCenter
                    color: "white"
                    font.pixelSize: 14
                    text: root.wallpaperDir
                    onAccepted: root.wallpaperDir = text
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            clip: true
            
            model: folderModel
            cellWidth: Math.floor(width / 3)
            cellHeight: 130

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 10
                    color: "#1e1e2e"
                    clip: true

                    scale: mouseArea.containsMouse ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                    Image {
                        anchors.fill: parent
                        source: "file://" + filePath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["awww", "img", filePath])
                        }
                    }
                }
            }
        }
    }
}
