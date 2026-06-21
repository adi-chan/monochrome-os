//@pragma UseQApplication

import QtQuick
import Quickshell
import qs.bar
import qs.bar.placeholders
import qs.services

ShellRoot {
    id: root


    // Variants {
    //     model: Quickshell.screens
    //     Wallpaper {
    //         required property var modelData
    //         screen: modelData
    //     }
    // }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            targetScreen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        Mask {
            required property var modelData
            targetScreen: modelData
        }
    }
}
