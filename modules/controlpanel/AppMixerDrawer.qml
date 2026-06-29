import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.services as Services
import "../../services" as ServicesUI

Rectangle {
    id: drawer
    
    radius: 16
    color: Services.Theme.bg
    border.color: Services.Theme.border
    border.width: 1
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    
    
    
    
    ListModel { id: appsModel }
    
    Process {
        id: pactlProcess
        command: ["sh", "-c", "pactl --format=json list sink-inputs || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text;
                let data;
                try {
                    data = JSON.parse(out);
                } catch(e) { 
                    return; 
                }
                
                let existingIds = [];
                for (let i = 0; i < appsModel.count; i++) {
                    existingIds.push(appsModel.get(i).nodeId);
                }
                
                for (let i = 0; i < data.length; i++) {
                    let n = data[i];
                    let appId = n.index;
                    let props = n.properties || {};
                    let appName = props["application.name"] || props["media.name"] || props["node.name"] || "Unknown";
                    
                    // Get volume from first channel
                    let volStr = "100%";
                    if (n.volume) {
                        let channels = Object.keys(n.volume);
                        if (channels.length > 0) {
                            volStr = n.volume[channels[0]].value_percent;
                        }
                    }
                    let vol = parseFloat(volStr);
                    
                    let existingIdx = existingIds.indexOf(appId);
                    if (existingIdx !== -1) {
                        // Update only if we aren't currently dragging it
                        if (!appsModel.get(existingIdx).isDragging) {
                            appsModel.setProperty(existingIdx, "volume", vol);
                        }
                        existingIds.splice(existingIds.indexOf(appId), 1);
                    } else {
                        appsModel.append({
                            nodeId: appId,
                            appName: appName,
                            volume: vol,
                            isDragging: false
                        });
                    }
                }
                
                // Remove apps that are no longer playing
                for (let i = appsModel.count - 1; i >= 0; i--) {
                    if (existingIds.includes(appsModel.get(i).nodeId)) {
                        appsModel.remove(i);
                    }
                }
            }
        }
    }
    
    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: drawer.visible
        onTriggered: {
            pactlProcess.running = false
            pactlProcess.running = true
        }
    }
    
    Component.onCompleted: {
        pactlProcess.running = true
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "App Mixer"
            color: Services.Theme.text
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Services.Theme.border
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 40
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
                        color: Services.Theme.highlight
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text {
                            anchors.centerIn: parent
                            text: model.appName ? model.appName.charAt(0).toUpperCase() : "?"
                            color: Services.Theme.text
                            font.pixelSize: 12
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                    Text {
                        text: model.appName || "Unknown"
                        color: Services.Theme.text
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
                    
                    colPrimary: Services.Theme.primary
                    colSecondaryContainer: Services.Theme.secondaryContainer
                    handleBorderColor: Services.Theme.border
                    handleBorderWidth: 1
                    trackHeightDiff: 15
                    handleGap: 6
                    trackNearHandleRadius: 2
                    useAnim: true
                    
                    Binding {
                        target: appSlider
                        property: "value"
                        value: model.volume
                        when: !model.isDragging
                    }
                    
                    Process { id: volProc }
                    
                    onUserMoved: (v) => {
                        model.isDragging = true;
                    }
                    
                    onUserReleased: (v) => {
                        let val = Math.round(v);
                        volProc.command = ["pactl", "set-sink-input-volume", String(model.nodeId), String(val) + "%"];
                        volProc.running = false;
                        volProc.running = true;
                        
                        model.volume = val;
                        model.isDragging = false;
                    }
                }
            }
        }
    }
    
    Text {
        visible: appsModel.count === 0
        text: "No apps playing audio"
        color: Services.Theme.subtext
        font.pixelSize: 13
        anchors.centerIn: parent
    }
}
