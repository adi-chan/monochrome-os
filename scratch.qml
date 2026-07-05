import QtQuick
import Quickshell
import Quickshell.Services.Notifications

ShellRoot {
    NotificationServer {
        id: server
        Component.onCompleted: {
            console.log("Server available")
            for (var p in server) {
                console.log(" -", p)
            }
            Qt.quit()
        }
    }
}
