import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property string city: "Loading..."
    property string tempC: "--"
    property string tempF: "--"
    property string feelsLikeC: "--"
    property string condition: "Fetching..."
    property string humidity: "--"
    property string windSpeed: "--"
    property string icon: "󰖐"
    property var forecast: []
    property bool loading: false

    function getWeatherIcon(text) {
        let t = (text || "").toLowerCase()
        if (t.includes("sun") || t.includes("clear")) return "󰖙"
        if (t.includes("partly")) return "󰖕"
        if (t.includes("cloud") || t.includes("overcast")) return "󰖐"
        if (t.includes("rain") || t.includes("drizzle") || t.includes("shower")) return "󰖗"
        if (t.includes("thunder")) return "󰖔"
        if (t.includes("snow") || t.includes("ice") || t.includes("sleet")) return "󰼶"
        if (t.includes("fog") || t.includes("mist")) return "󰖑"
        return "󰖐"
    }

    function refresh() {
        if (weatherProc.running) return
        root.loading = true
        weatherProc.running = false
        weatherProc.running = true
    }

    Timer {
        interval: 1800000 // Refresh every 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "--max-time", "10", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    if (text.trim().length === 0) return
                    let data = JSON.parse(text)
                    if (!data || !data.current_condition || data.current_condition.length === 0) return

                    let current = data.current_condition[0]
                    let area = (data.nearest_area && data.nearest_area.length > 0) ? data.nearest_area[0] : null

                    if (area && area.areaName && area.areaName.length > 0) {
                        root.city = area.areaName[0].value
                    } else {
                        root.city = "Local Weather"
                    }

                    root.tempC = current.temp_C + "°C"
                    root.tempF = current.temp_F + "°F"
                    root.feelsLikeC = current.FeelsLikeC + "°C"
                    let condText = current.weatherDesc[0].value.trim()
                    root.condition = condText
                    root.icon = root.getWeatherIcon(condText)
                    root.humidity = current.humidity + "%"
                    root.windSpeed = current.windspeedKmph + " km/h"

                    let days = []
                    let rawForecast = data.weather || []
                    for (let i = 0; i < Math.min(3, rawForecast.length); i++) {
                        let day = rawForecast[i]
                        let dateParts = day.date.split('-')
                        let dateObj = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]))
                        let dayLabel = i === 0 ? "Today" : (i === 1 ? "Tomorrow" : dateObj.toLocaleDateString('en-US', { weekday: 'short' }))
                        let dayCond = (day.hourly && day.hourly.length > 4) ? day.hourly[4].weatherDesc[0].value : ""
                        days.push({
                            day: dayLabel,
                            min: day.mintempC + "°",
                            max: day.maxtempC + "°",
                            icon: root.getWeatherIcon(dayCond)
                        })
                    }
                    root.forecast = days
                } catch (e) {
                    console.log("Weather JSON parse error:", e)
                }
            }
        }
    }
}
