pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isCookedOpen: false
    property var stats: ({
        cooked: { score: 0, tier: "CHILLED", summary: "Optimal", reasons: [] },
        cpu: { usage_percent: 0, temp: 40, load1: 0, load5: 0, load15: 0 },
        memory: { total_gb: 16, used_gb: 4, ram_percent: 25, swap_total_gb: 8, swap_used_gb: 0, swap_percent: 0 },
        battery: { present: true, capacity: 100, status: "AC", power_w: 0, temp: 30 },
        processes: { top_cpu: [], top_mem: [] },
        disk: { root_total_gb: 500, root_used_gb: 100, root_percent: 20 },
        active_window: { title: "", class: "" },
        usage_analytics: {
            uptime_formatted: "0m",
            days_tracked: 0,
            daily: { total_formatted: "0m", wasted_formatted: "0m", productive_formatted: "0m", top_apps: [] },
            weekly: { total_formatted: "0m", wasted_formatted: "0m", productive_formatted: "0m", top_apps: [] },
            monthly: { total_formatted: "0m", wasted_formatted: "0m", productive_formatted: "0m", top_apps: [] },
            lifetime: { total_formatted: "0m", wasted_formatted: "0m", productive_formatted: "0m", top_apps: [] }
        }
    })

    function toggle() {
        isCookedOpen = !isCookedOpen
        if (isCookedOpen) {
            refresh()
        }
    }

    function refresh() {
        if (!proc.running) {
            proc.running = true
        }
    }

    function killProcess(pid) {
        killProc.command = ["kill", "-9", pid.toString()]
        killProc.running = true
    }

    // ── BACKGROUND APP TRACKER ──────────────────────────────────────────────
    // Runs every 5 seconds ALL THE TIME (not just when panel is open).
    // Records which app is active so history accumulates even when panel is closed.
    Timer {
        id: bgTrackTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: {
            if (!bgTickProc.running) {
                bgTickProc.running = true
            }
        }
    }

    Process {
        id: bgTickProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/app_tracker.py", "--tick-only"]
        running: false
        // No stdout handler needed — tick-only produces no output
    }
    // ────────────────────────────────────────────────────────────────────────

    // File Trigger Poll (touch /tmp/qs_toggle_am_i_cooked to open)
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (!filePollProc.running) {
                filePollProc.running = true
            }
        }
    }

    Process {
        id: filePollProc
        command: ["bash", "-c", "if [ -f /tmp/qs_toggle_am_i_cooked ]; then rm -f /tmp/qs_toggle_am_i_cooked; echo 1; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "1") {
                    root.toggle()
                }
            }
        }
    }

    // Full stats refresh process (only runs when panel is open or manually triggered)
    Process {
        id: proc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/am_i_cooked.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.stats = JSON.parse(text)
                } catch(e) {
                    console.log("[AmICookedService] Error parsing JSON: " + e)
                }
            }
        }
    }

    Process {
        id: killProc
        running: false
        onExited: refresh()
    }

    // Auto-refresh stats display while panel is open
    Timer {
        interval: 3000
        running: root.isCookedOpen
        repeat: true
        onTriggered: root.refresh()
    }
}
