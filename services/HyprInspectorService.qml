import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property string windowClass: "Desktop"
    property string windowTitle: "Hyprland Workspace"
    property int workspaceId: 1
    property int pid: 0
    property int winWidth: 0
    property int winHeight: 0
    property bool isFloating: false
    property bool isFullscreen: false
    property string icon: "󰖯"
    property var activeWorkspaces: []

    function getAppIcon(cls) {
        let c = (cls || "").toLowerCase()
        if (c.includes("firefox") || c.includes("librewolf")) return ""
        if (c.includes("chromium") || c.includes("chrome") || c.includes("brave")) return ""
        if (c.includes("foot") || c.includes("kitty") || c.includes("alacritty") || c.includes("term")) return ""
        if (c.includes("code") || c.includes("antigravity")) return "󰨞"
        if (c.includes("thunar") || c.includes("nemo") || c.includes("dolphin")) return ""
        if (c.includes("discord") || c.includes("vesktop")) return "󰙯"
        if (c.includes("spotify")) return ""
        if (c.includes("steam")) return "󰓓"
        if (c.includes("mpv") || c.includes("vlc")) return ""
        return "󰖯"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            inspectorProc.running = false
            inspectorProc.running = true
        }
    }

    Process {
        id: inspectorProc
        command: ["bash", "-c", "echo '{ \"window\": '\"$(hyprctl activewindow -j 2>/dev/null || echo '{}')\"', \"workspaces\": '\"$(hyprctl workspaces -j 2>/dev/null || echo '[]')\"' }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim().length === 0) return
                    let data = JSON.parse(text)
                    let win = data.window || {}
                    let wss = data.workspaces || []

                    if (win.class && win.class !== "") {
                        root.windowClass = win.class
                        root.windowTitle = win.title || win.class
                        root.workspaceId = win.workspace ? win.workspace.id : 1
                        root.pid = win.pid || 0
                        if (win.size && win.size.length >= 2) {
                            root.winWidth = win.size[0]
                            root.winHeight = win.size[1]
                        }
                        root.isFloating = win.floating || false
                        root.isFullscreen = (win.fullscreen && win.fullscreen > 0) || false
                        root.icon = root.getAppIcon(win.class)
                    } else {
                        root.windowClass = "Desktop"
                        root.windowTitle = "Workspace Overview"
                        root.icon = "󰖯"
                        root.pid = 0
                        root.winWidth = 0
                        root.winHeight = 0
                        root.isFloating = false
                        root.isFullscreen = false
                    }

                    wss.sort((a, b) => a.id - b.id)
                    root.activeWorkspaces = wss
                } catch (e) {
                    console.log("Inspector parse error:", e)
                }
            }
        }
    }
}
