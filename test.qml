import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Component.onCompleted: {
        var ws = Hyprland.workspaces.values[0]
        if (ws) {
            console.log("Workspace properties:")
            for (var p in ws) {
                console.log(p)
            }
        }
        console.log("Does Hyprland have clients? " + (typeof Hyprland.clients !== "undefined"))
        Qt.quit()
    }
}
