//@pragma UseQApplication

import QtQuick
import Quickshell
import qs.bar
import qs.bar.placeholders
import qs.services
import qs.modules

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
    
    // Hot-Edge volume/brightness panel
    EdgeMixer {}

    // Notification Toasts
    Variants {
        model: Quickshell.screens
        NotificationToasts {
            required property var modelData
            screen: modelData
        }
    }

    // Add the Shortcut Wheel
    ShortcutWheel {
        // Overlay window on all screens or primary?
        // PanelWindow automatically handles screen assignment, or we can use Variants.
        // For a global launcher, let's use Variants to show it on all screens or we can just instantiate it.
        // Wait, ShortcutWheel is a PanelWindow, it might need to know which screen to show on.
        // If we don't specify, Quickshell usually picks the primary.
    }
}
