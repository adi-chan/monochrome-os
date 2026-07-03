import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services as Services
import qs.services as ServicesUI

Popup {
    id: pop

    opacity: 0
    
    // Smooth popup entrance animation
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutExpo }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 250; easing.type: Easing.OutBack }
            NumberAnimation { property: "y"; from: pop.y - 10; to: pop.y; duration: 250; easing.type: Easing.OutExpo }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // ===== config =====
    property int minWidth: 320
    property int maxWidth: 360
    property int maxListHeight: 350
    property int edgeMargin: 6

    // theme
    property color bg: "#1e1e2e" // dark surface
    property color border: "#313244"
    property color text: "#cdd6f4"
    property color subtext: "#a6adc8"
    
    // internal
    property Item boundsItem: null

    padding: 14
    width: minWidth
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property real contentW: pop.width - pop.leftPadding - pop.rightPadding

    ListModel { id: appsModel }
    
    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: pop.visible
        onTriggered: rebuild()
    }

    function clamp(n, lo, hi) { return Math.max(lo, Math.min(hi, n)) }

    function rebuild() {
        let clientNodes = Pipewire.nodes.values.filter(n => {
            let type = String(PwNodeType.toString?.(n.type) || PwNodeType[n.type]);
            let name = n.properties ? (n.properties["application.name"] || n.properties["media.name"] || n.properties["node.name"]) : null;
            return n.audio && name && type !== "AudioSink" && type !== "AudioSource" && type !== "Video";
        });
        
        let existingIds = [];
        for (let i = 0; i < appsModel.count; i++) {
            existingIds.push(appsModel.get(i).nodeId);
        }
        
        for (let n of clientNodes) {
            let vol = n.audio.volume * 100.0;
            let existingIdx = existingIds.indexOf(n.id);
            if (existingIdx !== -1) {
                appsModel.setProperty(existingIdx, "volume", vol);
                existingIds.splice(existingIds.indexOf(n.id), 1);
            } else {
                appsModel.append({
                    nodeId: n.id,
                    appName: n.properties["application.name"] || n.properties["media.name"] || n.properties["node.name"] || "Unknown",
                    volume: vol
                });
            }
        }
        
        for (let i = appsModel.count - 1; i >= 0; i--) {
            if (existingIds.includes(appsModel.get(i).nodeId)) {
                appsModel.remove(i);
            }
        }
    }

    function positionFrom(anchorItem) {
        if (!anchorItem || !pop.parent) return
        var p = anchorItem.mapToItem(pop.parent, 0, anchorItem.height)
        var desiredX = Math.round(p.x + anchorItem.width - pop.width)
        var minX = pop.edgeMargin
        var maxX = Math.max(minX, Math.round(pop.parent.width - pop.width - pop.edgeMargin))
        pop.x = clamp(desiredX, minX, maxX)
        pop.y = Math.round(p.y + 6)
    }

    function openFrom(anchorItem, bounds) {
        pop.boundsItem = bounds || anchorItem
        pop.parent = pop.boundsItem
        rebuild()
        positionFrom(anchorItem)
        pop.open()
    }

    background: Rectangle {
        radius: 16
        color: pop.bg
        border.width: 1
        border.color: pop.border
    }

    onAboutToShow: rebuild()

    Column {
        width: pop.contentW
        spacing: 12

        Text {
            text: "App Mixer"
            color: pop.text
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Services.Theme.bg
        }

        ListView {
            id: list
            width: parent.width
            implicitHeight: Math.min(pop.maxListHeight, contentHeight)
            clip: true
            spacing: 16
            model: appsModel

            delegate: ColumnLayout {
                width: list.width
                spacing: 6
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
                        color: Services.Theme.bg
                        Text {
                            anchors.centerIn: parent
                            text: model.appName ? model.appName.charAt(0).toUpperCase() : "?"
                            color: Services.Theme.text
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    Text {
                        text: model.appName || "Unknown"
                        color: pop.text
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                ServicesUI.StyledSlider {
                    id: appSlider
                    Layout.fillWidth: true
                    implicitHeight: 35
                    from: 0
                    to: 100
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    
                    colPrimary: "#ffffff"
                    colSecondaryContainer: "#454559"
                    handleBorderColor: "#313244"
                    handleBorderWidth: 1
                    trackHeightDiff: 15
                    handleGap: 6
                    trackNearHandleRadius: 2
                    useAnim: true
                    
                    Binding {
                        target: appSlider
                        property: "value"
                        value: model.volume
                        when: !appSlider.pressed
                    }
                    
                    Process { id: volProc }
                    
                    onUserMoved: (v) => {
                        let node = Pipewire.nodes.values.find(n => n.id === model.nodeId);
                        if (node && node.audio) node.audio.volume = v / 100.0;
                    }
                    
                    onUserReleased: (v) => {
                        let val = v / 100.0;
                        volProc.command = ["wpctl", "set-volume", String(model.nodeId), val.toFixed(2)];
                        volProc.running = false;
                        volProc.running = true;
                        
                        let node = Pipewire.nodes.values.find(n => n.id === model.nodeId);
                        if (node && node.audio) node.audio.volume = val;
                    }
                }
            }
        }

        Text {
            visible: appsModel.count === 0
            text: "No apps playing audio"
            color: pop.subtext
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
