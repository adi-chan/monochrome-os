pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property ListModel toastModel: ListModel {}
    property ListModel historyModel: ListModel {}
    property int unreadCount: 0

    NotificationServer {
        id: server
        onNotification: function(notification) {
            // Play sound
            playSoundProc.running = true
            
            // Add to unread
            unreadCount++
            
            // Add to toasts and history
            var notifData = {
                "notifId": notification.id,
                "summary": notification.summary,
                "body": notification.body,
                "appName": notification.appName,
                "appIcon": notification.appIcon,
                "image": notification.image
            }
            toastModel.append(notifData)
            // Insert at the top of history
            historyModel.insert(0, notifData)
        }
    }

    Process {
        id: playSoundProc
        command: ["pw-play", "/home/nick/.config/quickshell/assets/notif.mp3"]
        running: false
    }

    function openAttachedFile(imagePath, appIconPath) {
        console.log("openAttachedFile called with image:", imagePath, "appIcon:", appIconPath)
        var path = imagePath || appIconPath || ""
        
        // Handle path formatting
        if (path.startsWith("/")) {
            path = "file://" + path
        }
        
        if (path.startsWith("file://")) {
            path = path.replace(".thumb.jpg", "") // Handle any dunst thumbnails
            console.log("Opening file via Qt.openUrlExternally:", path)
            var success = Qt.openUrlExternally(path)
            console.log("Open success:", success)
            return success
        } else {
            console.log("Cannot open non-file path:", path)
        }
        return false
    }

    function removeToast(index) {
        toastModel.remove(index)
    }

    function clearUnread() {
        unreadCount = 0
    }
}
