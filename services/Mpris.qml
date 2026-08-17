import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root
    property string albumArtist: ""
    property string artUrl: ""
    property string albumTitle: "No Media"
    property string playbackStatus: "Stopped"

    property int positionSec: 0
    property int lengthSec: 0
    
    property string currentPlayer: ""
    property var availablePlayers: []
    property var playerArgs: {
        let args = ["playerctl", "--ignore-player=zen,firefox,chromium,chrome,brave,vivaldi,edge,opera"]
        if (currentPlayer !== "") {
            args.push("-p")
            args.push(currentPlayer)
        }
        return args
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: playersProc.running = true
    }

    Process {
        id: playersProc
        command: ["bash", "-c", "playerctl -l 2>/dev/null | grep -vE 'zen|firefox|chromium|chrome|brave|vivaldi|edge|opera' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").filter(Boolean)
                root.availablePlayers = lines
                if (lines.length > 0 && (!root.currentPlayer || !lines.includes(root.currentPlayer))) {
                    root.currentPlayer = lines[0]
                } else if (lines.length === 0) {
                    root.currentPlayer = ""
                }
            }
        }
    }

    function formatTime(seconds) {
        const m = Math.floor(seconds / 60)
        const s = Math.floor(seconds % 60)
        return `${m.toString().padStart(2,"0")}:${s.toString().padStart(2,"0")}`
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: artProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            posProcess.running = true
            lenProcess.running = true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: artistProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: titleProc.running = true
    }

    Process {
        id: artProc
        command: root.playerArgs.concat(["metadata", "mpris:artUrl"])
        stdout: StdioCollector {
            onStreamFinished: {
                // sanitize output (remove newlines/spaces)
                var cleanUrl = text.trim()
                if (cleanUrl !== root.artUrl)
                    root.artUrl = cleanUrl
            }
        }
    }

    Process {
        id: artistProc
        command: root.playerArgs.concat(["metadata", "xesam:artist"])
        stdout: StdioCollector {
            onStreamFinished: {
                var cleanedArtist = text.trim()
                if (cleanedArtist !== "")
                root.albumArtist = cleanedArtist
                else root.albumArtist = "No Artist"
            }
        }
    }

    Process {
        id: titleProc
        command: root.playerArgs.concat(["metadata", "xesam:title"])
        stdout: StdioCollector {
            onStreamFinished: {
                var cleanedtitle = text.trim()
                if (cleanedtitle !== "")
                root.albumTitle = cleanedtitle
                else root.albumTitle = "No Media"


            }
        }
    }

    Process {
        id: posProcess
        command: root.playerArgs.concat(["position"])
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseFloat(text.trim())
                if (!isNaN(val))
                    root.positionSec = val
            }
        }
    }
    
    Process { id: playPauseProc; command: root.playerArgs.concat(["play-pause"]) }
        function playPause() {
            playPauseProc.running = false
            playPauseProc.running = true
    }

    Process { id: pauseCurrentProc; command: root.playerArgs.concat(["pause"]) }
    function pauseCurrent() {
        pauseCurrentProc.running = false
        pauseCurrentProc.running = true
    }


    Process {
        id: lenProcess
        command: root.playerArgs.concat(["metadata", "mpris:length"])
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseFloat(text.trim())
                if (!isNaN(val))
                    root.lengthSec = val / 1000000
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }
    
    Process {
        id: statusProc
        command: root.playerArgs.concat(["status"])
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var isPlaying = false
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "Playing") {
                        isPlaying = true
                        break
                    }
                }
                root.playbackStatus = isPlaying ? "Playing" : (lines.length > 0 && lines[0] !== "" ? lines[0].trim() : "Stopped")
            }
        }
    }
}