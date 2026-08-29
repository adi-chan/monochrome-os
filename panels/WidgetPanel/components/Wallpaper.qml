import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services as Services

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string wallpaperDir: "/home/nick/Backgrounds"
    property bool showPathInput: false
    property string activeWallpaperPath: ""
    property string currentPreviewPath: ""
    property bool userInteracted: false

    Component.onCompleted: {
        loadPathProc.running = true
        loadCurrentWallProc.running = true
    }

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
        id: loadCurrentWallProc
        command: ["bash", "-c", "awww query 2>/dev/null | grep -oP 'image:\\s*\\K\\S+' || swww query 2>/dev/null | grep -oP 'image:\\s*\\K\\S+' || cat ~/.config/quickshell/assets/current_wallpaper.txt 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim()
                if (p.length > 0) {
                    root.activeWallpaperPath = p
                    root.currentPreviewPath = p
                    root.syncCurrentIndexToPath(p)
                }
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
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.JPG", "*.PNG", "*.WEBP", "*.JPEG"]
        showDirs: false
        onCountChanged: {
            if (count > 0 && root.activeWallpaperPath !== "") {
                Qt.callLater(() => {
                    root.syncCurrentIndexToPath(root.activeWallpaperPath)
                })
            }
        }
    }

    function syncCurrentIndexToPath(targetPath) {
        if (!targetPath || folderModel.count === 0) return
        for (let i = 0; i < folderModel.count; i++) {
            let itemPath = folderModel.get(i, "filePath")
            if (itemPath === targetPath || itemPath.endsWith(targetPath) || targetPath.endsWith(itemPath)) {
                coverflow.currentIndex = i
                coverflow.positionViewAtIndex(i, ListView.Beginning)
                return
            }
        }
    }

    function previewLiveWallpaper(path) {
        if (!path || path === "" || path === root.currentPreviewPath) return
        root.currentPreviewPath = path
        let cmd = "awww img '" + path + "' --transition-type simple --transition-step 255 2>/dev/null || swww img '" + path + "' --transition-type simple 2>/dev/null"
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function applyWallpaper(path) {
        if (!path || path === "") return
        let transitions = ["outer", "wave", "wipe", "grow", "left", "right", "top", "bottom", "simple"]
        let trans = transitions[Math.floor(Math.random() * transitions.length)]
        let cmd = "echo '" + path + "' > ~/.config/quickshell/assets/current_wallpaper.txt; awww img '" + path + "' --transition-type " + trans + " --transition-step 90 --transition-fps 60 2>/dev/null || swww img '" + path + "' --transition-type " + trans + " 2>/dev/null || awww img '" + path + "' || swww img '" + path + "'"
        Quickshell.execDetached(["bash", "-c", cmd])
        root.activeWallpaperPath = path
        root.currentPreviewPath = path
    }

    function cleanName(fileName) {
        if (!fileName) return ""
        return fileName.replace(/\.[^/.]+$/, "")
    }

    // Main Wallpaper Gallery Card Box (Full height container)
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Services.Theme.bg
        border.color: Services.Theme.border
        border.width: 1
        clip: true

        ListView {
            id: coverflow
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            clip: true
            orientation: ListView.Horizontal
            spacing: 16
            model: folderModel

            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (coverflow.width - 380) / 2
            preferredHighlightEnd: (coverflow.width + 380) / 2

            onMovementStarted: root.userInteracted = true
            onFlickStarted: root.userInteracted = true

            onCurrentIndexChanged: {
                if (root.userInteracted && currentIndex >= 0 && currentIndex < folderModel.count) {
                    let path = folderModel.get(currentIndex, "filePath")
                    root.previewLiveWallpaper(path)
                }
            }

            delegate: Item {
                id: delegateRoot
                width: 380
                height: coverflow.height

                readonly property bool isCurrent: ListView.isCurrentItem

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    // Image Card Container (Uniformly rounded corners on all images)
                    Rectangle {
                        id: cardContainer
                        Layout.preferredWidth: delegateRoot.isCurrent ? 380 : 290
                        Layout.preferredHeight: delegateRoot.isCurrent ? 212 : 162
                        Layout.alignment: Qt.AlignHCenter
                        radius: 14
                        color: Services.Theme.bgSolid
                        opacity: delegateRoot.isCurrent ? 1.0 : 0.70

                        // Pop-Up Vertical Lift Animation
                        transform: Translate {
                            y: delegateRoot.isCurrent ? -8 : 0
                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        border.color: delegateRoot.isCurrent ? Services.Theme.primary : Qt.alpha(Services.Theme.border, 0.5)
                        border.width: delegateRoot.isCurrent ? 2 : 1

                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        // Source wallpaper image
                        Image {
                            id: rawImg
                            anchors.fill: parent
                            source: "file://" + filePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            mipmap: true
                            smooth: true
                            visible: false
                        }

                        // Rounded Mask Shape
                        Rectangle {
                            id: maskShape
                            anchors.fill: parent
                            radius: 14
                            color: "black"
                            visible: false
                            layer.enabled: true
                        }

                        // MultiEffect applying exact rounded corner mask to every image
                        MultiEffect {
                            anchors.fill: parent
                            source: rawImg
                            maskEnabled: true
                            maskSource: maskShape
                        }

                        // Glow border overlay on active
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: Qt.alpha(Services.Theme.primary, 0.5)
                            border.width: 1
                            visible: delegateRoot.isCurrent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.userInteracted = true
                                coverflow.currentIndex = index
                                root.applyWallpaper(filePath)
                            }
                        }
                    }

                    // Filename Label Underneath
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.cleanName(fileName)
                        font.family: "JetBrains Mono"
                        font.pixelSize: delegateRoot.isCurrent ? 11 : 10
                        font.weight: delegateRoot.isCurrent ? 700 : 500
                        color: delegateRoot.isCurrent ? Services.Theme.text : Services.Theme.subtext
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 370
                    }
                }
            }
        }
    }

    // Floating Folder Directory Picker Pill (Bottom-Left Overlay)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 10
        z: 30
        height: 28
        width: root.showPathInput ? 320 : 28
        color: Qt.alpha(Services.Theme.bg, 0.92)
        radius: 8
        border.color: Services.Theme.border
        border.width: 1
        clip: true

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 6
            spacing: 6

            // Folder Icon Toggle Button
            Rectangle {
                width: 20; height: 20
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "📁"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPathInput = !root.showPathInput
                }
            }

            // Path Input Text Field
            TextInput {
                id: pathInput
                Layout.fillWidth: true
                visible: root.showPathInput
                verticalAlignment: Qt.AlignVCenter
                color: Services.Theme.text
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                selectByMouse: true
                clip: true
                text: root.wallpaperDir
                onAccepted: root.wallpaperDir = text
            }
        }
    }
}
