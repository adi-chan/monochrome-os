import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services as Services
import QtQuick.Effects

PanelWindow {
    id: toastWin
    color: "transparent"
    
    anchors {
        top: true
        right: true
        bottom: false
        left: false
    }
    
    margins {
        top: 20
        right: 20
    }
    
    implicitWidth: 320
    implicitHeight: Math.max(10, listView.contentHeight)

    // Window must be transparent and allow clickthrough where there are no toasts
    // Actually, Quickshell handles this if color is transparent, but we only have height if we have toasts!
    
    ListView {
        id: listView
        width: parent.width
        height: contentHeight
        model: Services.Notifications.toastModel
        spacing: 12
        interactive: false
        
        // Add item animation
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 300; to: 0; duration: 400; easing.type: Easing.OutElastic; easing.amplitude: 0.9; easing.period: 0.5 }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; to: 50; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: toastItem
            width: listView.width
            height: contentLayout.implicitHeight + 24
            
            // Auto close timer
            Timer {
                interval: 5000 // 5 seconds
                running: true
                onTriggered: {
                    Services.Notifications.removeToast(index)
                }
            }

            Rectangle {
                id: bgRect
                anchors.fill: parent
                color: Services.Theme.bgSolid
                radius: 12
                antialiasing: true
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: 0.3
                    shadowVerticalOffset: 4
                    shadowBlur: 0.6
                }
            }
            
            RowLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                // Optional App Icon or image
                Image {
                    visible: model.image !== "" || model.appIcon !== ""
                    source: model.image !== "" ? model.image : (model.appIcon !== "" ? model.appIcon : "")
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    fillMode: Image.PreserveAspectCrop
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: 48
                                height: 48
                                radius: 8
                            }
                        }
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: model.appName
                        color: Services.Theme.subtext
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                        font.weight: 600
                        visible: model.appName !== ""
                    }
                    
                    Text {
                        text: model.summary
                        color: Services.Theme.text
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                        font.weight: 800
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: model.body
                        color: Services.Theme.subtext
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: model.body !== ""
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Services.Notifications.openAttachedFile(model.image, model.appIcon)
                    Services.Notifications.removeToast(index)
                }
            }
        }
    }
}
