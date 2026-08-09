import Quickshell
import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root
    property string hostname: ""
    property string username: ""
    property string osIcon: ""
    property string osName: ""
    property string uptime: ""
    property string message: ""
    

    readonly property var osIcons: ({
        almalinux: "",
        alpine: "",
        arch: "󰣇",
        archcraft: "",
        arcolinux: "",
        artix: "",
        centos: "",
        debian: "",
        devuan: "",
        elementary: "",
        endeavouros: "",
        fedora: "",
        freebsd: "",
        garuda: "",
        gentoo: "",
        hyperbola: "",
        kali: "",
        linuxmint: "󰣭",
        mageia: "",
        openmandriva: "",
        manjaro: "",
        neon: "",
        nixos: "",
        opensuse: "",
        suse: "",
        sles: "",
        sles_sap: "",
        "opensuse-tumbleweed": "",
        parrot: "",
        pop: "",
        raspbian: "",
        rhel: "",
        rocky: "",
        slackware: "",
        solus: "",
        steamos: "",
        tails: "",
        trisquel: "",
        ubuntu: "",
        vanilla: "",
        void: "",
        zorin: ""
    })

    Process {
        id: usernameProc
        running: true 
        command: ["whoami"]
        stdout: StdioCollector {
            onStreamFinished: {
                // sanitize output (remove newlines/spaces)
                var clean = text.trim()
                if (clean !== root.username)
                    root.username = clean
            }
        }
    }

    Process {
        id: hostnameProc
        command: ["uname", "-n"]
        running: true 
        stdout: StdioCollector {
            onStreamFinished: {
                var cleanH = text.trim()
                if (cleanH !== "")
                root.hostname = cleanH
                else root.hostname = "aelyx"
            }
        }
    }

    Timer {
        running: true 
        repeat: true 
        interval: 60000
        onTriggered: uptimeProc.running = true
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var cleanT = text.trim()
                if (cleanT !== "")
                root.uptime = cleanT
                else root.uptime = "0 hours, 0 minutes"
            }
        }
    }

    Process {
    id: messageProc
    command: ["sh", "-lc", "~/.config/scripts/notify.sh"]
    running: true

    stdout: StdioCollector {
        onStreamFinished: {
            const clean = text.trim()
            root.message = clean !== "" ? clean : ""
        }
    }
}


    FileView {
        path: "/etc/os-release"
        onLoaded: {
        const lines = text().split("\n");
        let osId = lines.find(l => l.startsWith("ID="))?.split("=")[1];
        if (root.osIcons.hasOwnProperty(osId))
            root.osIcon = root.osIcons[osId];
        else {
            const osIdLike = lines.find(l => l.startsWith("ID_LIKE="))?.split("=")[1];
            if (osIdLike)
            for (const id of osIdLike.split(" "))
                if (root.osIcons.hasOwnProperty(id))
                    return root.osIcon = root.osIcons[id];
        }

        let nameLine = lines.find(l => l.startsWith("PRETTY_NAME="));
        if (!nameLine)
            nameLine = lines.find(l => l.startsWith("NAME="));
        root.osName = nameLine.split("=")[1].slice(1, -1);
        }
    }

    property real cpuUsage: 0
    property real ramUsage: 0
    property real diskUsage: 0
    property string diskText: ""
    property string ramText: ""

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
            diskProc.running = true
        }
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseFloat(text.trim())
                if (!isNaN(v)) root.cpuUsage = v
            }
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | grep Mem | awk '{print $3/$2 * 100.0, $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    let pct = parseFloat(parts[0])
                    let usedBytes = parseFloat(parts[1]) * 1024
                    if (!isNaN(pct)) root.ramUsage = pct
                    
                    let gb = (usedBytes / (1024*1024*1024)).toFixed(1)
                    root.ramText = gb + "GB"
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df / | tail -1 | awk '{print $5, $3}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(" ")
                if (parts.length >= 2) {
                    let pct = parseFloat(parts[0].replace('%',''))
                    let usedK = parseFloat(parts[1])
                    if (!isNaN(pct)) root.diskUsage = pct
                    
                    let gb = (usedK / (1024*1024)).toFixed(1)
                    root.diskText = gb + "GB"
                }
            }
        }
    }

}