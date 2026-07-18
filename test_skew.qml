import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    width: 800
    height: 600
    visible: true
    color: "#222"

    Row {
        anchors.centerIn: parent
        spacing: -20 // overlap to account for skew

        Repeater {
            model: 5
            delegate: Item {
                id: container
                width: hovered ? 300 : 80
                height: 400
                z: hovered ? 10 : 1

                property bool hovered: false

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                Rectangle {
                    id: rect
                    width: parent.width
                    height: parent.height
                    color: index % 2 == 0 ? "#e74c3c" : "#3498db"
                    clip: true
                    
                    // The skew animation
                    property real skew: container.hovered ? 0 : -0.3
                    Behavior on skew { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(
                            1, skew, 0, -skew * rect.height / 2,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            0, 0, 0, 1
                        )
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Item " + index
                        color: "white"
                        font.pixelSize: 24
                        rotation: 0 // Keep text straight if possible? Wait, the whole rect is skewed, so children are skewed too.
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: container.hovered = true
                        onExited: container.hovered = false
                    }
                }
            }
        }
    }
}
