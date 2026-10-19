import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property string cpuUsage: "0%"
    property string memUsage: "0.0G"
    property string cpuTemp: ""
    property string gpuTemp: ""

    property var lastCpuStat: [0, 0]

    // Read /proc/stat for accurate CPU usage without subprocesses
    FileView {
        id: procStat
        path: "/proc/stat"
    }

    // Read /proc/meminfo for memory without subprocesses
    FileView {
        id: procMem
        path: "/proc/meminfo"
    }

    // Process for hyde-shell cpuinfo
    Process {
        id: cpuInfoProc
        command: ["hyde-shell", "cpuinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    if (res && res.text) root.cpuTemp = res.text;
                } catch (e) {}
            }
        }
    }

    // Process for hyde-shell gpuinfo
    Process {
        id: gpuInfoProc
        command: ["hyde-shell", "gpuinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    if (res && res.text) root.gpuTemp = res.text;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            updateCpu();
            updateMem();
            cpuInfoProc.running = true;
            gpuInfoProc.running = true;
        }
    }

    function updateCpu() {
        let text = procStat.text();
        if (!text) return;
        let line = text.split("\n")[0];
        let parts = line.trim().split(/\s+/).slice(1).map(Number);
        if (parts.length < 4) return;
        
        let idle = parts[3] + (parts[4] || 0);
        let total = parts.reduce((a, b) => a + b, 0);

        if (root.lastCpuStat[1] > 0) {
            let diffIdle = idle - root.lastCpuStat[0];
            let diffTotal = total - root.lastCpuStat[1];
            if (diffTotal > 0) {
                let usage = Math.round(100 * (diffTotal - diffIdle) / diffTotal);
                root.cpuUsage = usage + "%";
            }
        }
        root.lastCpuStat = [idle, total];
    }

    function updateMem() {
        let text = procMem.text();
        if (!text) return;
        let totalKb = 0;
        let availKb = 0;
        let lines = text.split("\n");
        for (let i = 0; i < lines.length && i < 5; i++) {
            let l = lines[i];
            if (l.startsWith("MemTotal:")) totalKb = parseInt(l.replace(/\D/g, ''));
            if (l.startsWith("MemAvailable:")) availKb = parseInt(l.replace(/\D/g, ''));
        }
        if (totalKb > 0) {
            let usedGb = (totalKb - availKb) / 1048576;
            root.memUsage = usedGb.toFixed(1) + "G";
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        // CPU
        IslandButton {
            icon: "󰍛"
            text: root.cpuUsage
            tooltip: "CPU: " + root.cpuUsage + (root.cpuTemp !== "" ? " (" + root.cpuTemp + ")" : "")
        }

        // Memory
        IslandButton {
            icon: "󰾆"
            text: root.memUsage
            tooltip: "Memory Used: " + root.memUsage
        }

        // CPU Info Temp
        IslandButton {
            visible: root.cpuTemp !== ""
            text: root.cpuTemp
            tooltip: "CPU Temperature"
        }

        // GPU Info Temp
        IslandButton {
            visible: root.gpuTemp !== ""
            text: root.gpuTemp
            tooltip: "GPU Info (Click to toggle)"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell gpuinfo --toggle");
            }
        }
    }
}
