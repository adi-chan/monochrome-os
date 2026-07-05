import QtQuick
import QtQuick.Shapes
import Quickshell

ShellRoot {
    Component.onCompleted: {
        console.log("Shapes works");
        Qt.quit()
    }
    Shape {
        ShapePath {
            startX: 0; startY: 0
            PathLine { x: 100; y: 100 }
        }
    }
}
