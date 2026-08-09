import QtQuick 2.15
import QtQuick.Shapes 1.15
import qs.services as Services

Item {
    id: root
    property color color: Services.Theme.bgSolid
    property int notchWidth: 100
    property int gapHeight: 12
    property int overlap: 2 // Overlap to hide borders

    width: notchWidth + gapHeight * 2
    height: gapHeight + overlap

    property real waveOffset: 0
    NumberAnimation on waveOffset {
        from: 0
        to: Math.PI * 2
        duration: 2000
        loops: Animation.Infinite
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4 // Anti-aliasing for smooth curves

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            startX: root.gapHeight
            startY: 0
            
            // Left fluid flare
            PathCubic {
                x: 0
                y: root.gapHeight
                control1X: root.gapHeight - Math.sin(root.waveOffset)*2
                control1Y: root.gapHeight * 0.4
                control2X: root.gapHeight * 0.4
                control2Y: root.gapHeight - Math.cos(root.waveOffset)*2
            }
            
            // Left overlap edge
            PathLine { x: 0; y: root.gapHeight + root.overlap }
            
            // Bottom overlap edge (hidden under popup)
            PathLine { x: root.width; y: root.gapHeight + root.overlap }
            
            // Right overlap edge
            PathLine { x: root.width; y: root.gapHeight }
            
            // Right fluid flare
            PathCubic {
                x: root.width - root.gapHeight
                y: 0
                control1X: root.width - root.gapHeight * 0.4
                control1Y: root.gapHeight - Math.sin(root.waveOffset)*2
                control2X: root.width - root.gapHeight + Math.cos(root.waveOffset)*2
                control2Y: root.gapHeight * 0.4
            }
            
            // Top flat edge
            PathLine { x: root.gapHeight; y: 0 }
        }
    }
}
