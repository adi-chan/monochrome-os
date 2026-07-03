// modules/controlpanel/ProfilePicture.qml
import QtQuick
import qs.services as Services
import Quickshell
import Quickshell.Widgets

ClippingRectangle {
    id: avatar
    implicitWidth: 80
    implicitHeight: 80
    radius: 14
    antialiasing: true
    layer.enabled: true
    layer.smooth: true
    color: Services.Theme.bg

    // Default to ~/.config/quickshell/assets/pfp.jpg
    property url source: "file:///home/nick/.config/quickshell/assets/pfp.jpg"

    Image {
        anchors.fill: parent
        source: avatar.source
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        antialiasing: true
        cache: false
    }
}
