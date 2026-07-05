import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.datetimepanel
import qs.services as Services

PanelWindow {
    id: popup
    visible: false
    color: "transparent"
    exclusiveZone: 0
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property color panelBg: Services.Theme.bgSolid
    property color panelBorder: Services.Theme.border

    anchors { top: true; bottom: false; left: false; right: false }
    margins { top: 6 }
    
    implicitWidth: 480
    implicitHeight: 240

    function toggle() {
        visible = !visible;
    }

    HyprlandFocusGrab {
        windows: [ popup ]
        active: popup.visible
        onCleared: popup.visible = false
    }

    PanelWindow {
        id: backdrop
        color: "transparent"
        visible: popup.visible
        exclusiveZone: -1
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onPressed: popup.visible = false
        }
    }

    Item {
        anchors.fill: parent
        
        y: popup.visible ? 0 : -20
        opacity: popup.visible ? 1.0 : 0.0
        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: 16
            color: popup.panelBg
            border.width: 1
            border.color: popup.panelBorder
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: 0.25
                shadowBlur: 0.5
                shadowVerticalOffset: 4
            }

            TimerWidget {
                anchors.fill: parent
                anchors.margins: 16
            }
        }
    }
}
