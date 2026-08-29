import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property var animeList: []
    property bool loading: false

    function refresh() {
        if (animeProc.running) return
        root.loading = true
        let query = '{ "query": "query { Page(page: 1, perPage: 12) { airingSchedules(notYetAired: true, sort: TIME) { episode timeUntilAiring media { title { english romaji } } } } }" }'
        animeProc.command = ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json", "-d", query, "https://graphql.anilist.co"]
        animeProc.running = false
        animeProc.running = true
    }

    Timer {
        interval: 60000 // Refresh every minute for live countdown updates
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: animeProc
        command: ["curl", "-s", "https://graphql.anilist.co"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    if (text.trim().length === 0) return
                    let data = JSON.parse(text)
                    if (!data || !data.data || !data.data.Page) return
                    let raw = data.data.Page.airingSchedules || []
                    let items = []

                    for (let i = 0; i < raw.length; i++) {
                        let item = raw[i]
                        let media = item.media || {}
                        let titleObj = media.title || {}
                        let title = titleObj.english || titleObj.romaji || "Anime"
                        let ep = "Ep " + item.episode
                        let secs = item.timeUntilAiring || 0
                        let hrs = Math.floor(secs / 3600)
                        let mins = Math.floor((secs % 3600) / 60)
                        let timeStr = ""
                        if (hrs > 24) {
                            let days = Math.floor(hrs / 24)
                            let rHrs = hrs % 24
                            timeStr = "in " + days + "d " + rHrs + "h"
                        } else if (hrs > 0) {
                            timeStr = "in " + hrs + "h " + mins + "m"
                        } else {
                            timeStr = "in " + mins + "m"
                        }

                        items.push({
                            title: title,
                            ep: ep,
                            countdown: timeStr
                        })
                    }
                    root.animeList = items
                } catch (e) {
                    console.log("AniList JSON parse error:", e)
                }
            }
        }
    }
}
