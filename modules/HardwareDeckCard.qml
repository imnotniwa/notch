import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    // =========================================================================
    // Telemetry State
    // =========================================================================
    // CPU
    property real cpuFraction: 0.0
    property string cpuUsageText: "0%"
    property string cpuTempText: "55°C"
    property string fanSpeedText: "2600 RPM"
    property var lastCpuStat: [0, 0]
    property var cpuHistory: [0.1, 0.15, 0.12, 0.2, 0.18, 0.25, 0.22, 0.3, 0.28, 0.2, 0.18, 0.22, 0.35, 0.28, 0.22, 0.19, 0.24, 0.26, 0.22, 0.2]

    // Memory
    property real memFraction: 0.0
    property string memUsedText: "0.0G"
    property string memTotalText: "0.0G"
    property string memPercentText: "0%"
    property real memAppFraction: 0.0
    property real memCacheFraction: 0.0
    property string memCacheText: "0.0G"

    // Storage
    property real diskFraction: 0.0
    property string diskUsedText: "0.0G"
    property string diskTotalText: "0.0G"
    property string diskPercentText: "0%"
    property string diskTempText: "38°C"

    // Network
    property string netDownText: "0 B/s"
    property string netUpText: "0 B/s"
    property var lastNetBytes: [0, 0, 0] // [rx, tx, timestamp]
    property var netHistory: [0.05, 0.08, 0.04, 0.12, 0.06, 0.15, 0.22, 0.18, 0.1, 0.05, 0.08, 0.14, 0.25, 0.18, 0.12, 0.09, 0.06, 0.08, 0.12, 0.1]

    // Filesystem FileViews
    FileView { id: procStat; path: "/proc/stat" }
    FileView { id: procMem; path: "/proc/meminfo" }

    // =========================================================================
    // Telemetry Update Functions
    // =========================================================================
    function updateCpu() {
        let text = procStat.text();
        if (!text) return;
        let line = text.split("\n")[0];
        let parts = line.trim().split(/\s+/).slice(1).map(Number);
        if (parts.length < 4) return;

        let idle = parts[3] + (parts[4] || 0);
        let total = parts.reduce((a, b) => a + b, 0);

        if (root.lastCpuStat[1] > 0) {
            let diffTotal = total - root.lastCpuStat[1];
            let diffIdle = idle - root.lastCpuStat[0];
            if (diffTotal > 0) {
                let usage = Math.max(0, Math.min(1, (diffTotal - diffIdle) / diffTotal));
                root.cpuFraction = usage;
                root.cpuUsageText = Math.round(usage * 100) + "%";

                let hist = root.cpuHistory.slice(1);
                hist.push(usage);
                root.cpuHistory = hist;
                cpuCanvas.requestPaint();
            }
        }
        root.lastCpuStat = [idle, total];
    }

    function updateMem() {
        let text = procMem.text();
        if (!text) return;
        let lines = text.split("\n");
        let memTotal = 0, memFree = 0, memAvail = 0, cached = 0, buffers = 0;

        for (let i = 0; i < Math.min(lines.length, 12); i++) {
            let l = lines[i];
            if (l.startsWith("MemTotal:")) memTotal = parseInt(l.replace(/\D/g, ""));
            else if (l.startsWith("MemFree:")) memFree = parseInt(l.replace(/\D/g, ""));
            else if (l.startsWith("MemAvailable:")) memAvail = parseInt(l.replace(/\D/g, ""));
            else if (l.startsWith("Cached:")) cached = parseInt(l.replace(/\D/g, ""));
            else if (l.startsWith("Buffers:")) buffers = parseInt(l.replace(/\D/g, ""));
        }

        if (memTotal > 0) {
            let used = memTotal - (memAvail > 0 ? memAvail : memFree);
            let frac = Math.max(0, Math.min(1, used / memTotal));
            root.memFraction = frac;
            root.memUsedText = (used / 1048576).toFixed(1) + "G";
            root.memTotalText = (memTotal / 1048576).toFixed(1) + "G";
            root.memPercentText = Math.round(frac * 100) + "%";

            let cacheGb = ((cached + buffers) / 1048576);
            root.memCacheText = cacheGb.toFixed(1) + "G";
            root.memCacheFraction = Math.max(0, Math.min(1, (cached + buffers) / memTotal));
            root.memAppFraction = Math.max(0, frac - root.memCacheFraction);
        }
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s";
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
    }

    // Process for live network, temps, fan, and disk
    Process {
        id: sysProc
        command: [
            "sh", "-c",
            "cat /proc/net/dev 2>/dev/null; echo '===DF==='; df -m / 2>/dev/null | awk 'NR==2 {print $3, $2, $5}'; echo '===TEMPS==='; cat /sys/class/hwmon/hwmon5/temp1_input /sys/class/hwmon/hwmon4/fan1_input /sys/class/hwmon/hwmon3/temp1_input 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (!raw) return;

                // 1. Network Dev
                let sections = raw.split("===DF===");
                let netRaw = sections[0] || "";
                let nowMs = Date.now();

                let rxTotal = 0;
                let txTotal = 0;
                let netLines = netRaw.split("\n");
                for (let i = 0; i < netLines.length; i++) {
                    let l = netLines[i].trim();
                    if (l.startsWith("wlan") || l.startsWith("eth") || l.startsWith("en") || l.startsWith("wl")) {
                        let parts = l.split(":")[1].trim().split(/\s+/);
                        rxTotal += parseInt(parts[0]) || 0;
                        txTotal += parseInt(parts[8]) || 0;
                    }
                }

                if (root.lastNetBytes[2] > 0) {
                    let dt = (nowMs - root.lastNetBytes[2]) / 1000.0;
                    if (dt > 0.5) {
                        let rxSpeed = Math.max(0, (rxTotal - root.lastNetBytes[0]) / dt);
                        let txSpeed = Math.max(0, (txTotal - root.lastNetBytes[1]) / dt);
                        root.netDownText = root.formatSpeed(rxSpeed);
                        root.netUpText = root.formatSpeed(txSpeed);

                        let hist = root.netHistory.slice(1);
                        let norm = Math.min(1.0, rxSpeed / (10 * 1048576));
                        hist.push(norm);
                        root.netHistory = hist;
                        netCanvas.requestPaint();
                    }
                }
                root.lastNetBytes = [rxTotal, txTotal, nowMs];

                // 2. Disk & Temps
                if (sections.length > 1) {
                    let rest = sections[1].split("===TEMPS===");
                    let dfParts = rest[0].trim().split(/\s+/);
                    if (dfParts.length >= 3) {
                        let usedMb = parseInt(dfParts[0]);
                        let totalMb = parseInt(dfParts[1]);
                        root.diskUsedText = (usedMb / 1024).toFixed(1) + "G";
                        root.diskTotalText = (totalMb / 1024).toFixed(1) + "G";
                        root.diskPercentText = dfParts[2];
                        root.diskFraction = totalMb > 0 ? (usedMb / totalMb) : 0;
                    }

                    // 3. Hardware sensors (CPU Temp, Fan, NVMe Temp)
                    if (rest.length > 1) {
                        let tempLines = rest[1].trim().split("\n");
                        let cpuRaw = parseInt(tempLines[0]);
                        if (!isNaN(cpuRaw) && cpuRaw > 0) {
                            root.cpuTempText = Math.round(cpuRaw / 1000) + "°C";
                        }
                        let fanRaw = parseInt(tempLines[1]);
                        if (!isNaN(fanRaw) && fanRaw > 0) {
                            root.fanSpeedText = fanRaw + " RPM";
                        }
                        let nvmeRaw = parseInt(tempLines[2]);
                        if (!isNaN(nvmeRaw) && nvmeRaw > 0) {
                            root.diskTempText = Math.round(nvmeRaw / 1000) + "°C";
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: Config.notchVisible
        triggeredOnStart: true
        onTriggered: {
            root.updateCpu();
            root.updateMem();
            sysProc.running = true;
        }
    }

    Component.onCompleted: {
        root.updateCpu();
        root.updateMem();
        sysProc.running = true;
    }

    // =========================================================================
    // Layout: 2x2 Telemetry Graph Deck (Option 2 - Clean & Focused)
    // =========================================================================
    GridLayout {
        anchors.fill: parent
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        // =====================================================================
        // Panel 1: CPU Activity & Rolling History Waveform
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "󰍛"
                            color: Config.actBg
                            font.family: Config.iconFont
                            font.pixelSize: 13
                        }
                        Text {
                            text: "CPU"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.cpuUsageText + " · " + root.cpuTempText + " · " + root.fanSpeedText
                        color: Config.mainFg
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                // Live Rolling Waveform Canvas
                Canvas {
                    id: cpuCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        let pts = root.cpuHistory;
                        if (!pts || pts.length < 2) return;

                        let step = width / (pts.length - 1);

                        // Gradient Fill
                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        for (let i = 0; i < pts.length; i++) {
                            let y = height - (pts[i] * (height - 4));
                            ctx.lineTo(i * step, y);
                        }
                        ctx.lineTo(width, height);
                        ctx.closePath();

                        let grad = ctx.createLinearGradient(0, 0, 0, height);
                        grad.addColorStop(0, Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.35));
                        grad.addColorStop(1, Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.02));
                        ctx.fillStyle = grad;
                        ctx.fill();

                        // Waveform Line
                        ctx.beginPath();
                        for (let i = 0; i < pts.length; i++) {
                            let y = height - (pts[i] * (height - 4));
                            if (i === 0) ctx.moveTo(0, y);
                            else ctx.lineTo(i * step, y);
                        }
                        ctx.strokeStyle = Config.actBg;
                        ctx.lineWidth = 2;
                        ctx.stroke();
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("hyprctl dispatch exec [float] btop || missioncenter || htop")
            }
        }

        // =====================================================================
        // Panel 2: Memory Breakdown (App vs Cache vs Free)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "󰘚"
                            color: "#af52de"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                        }
                        Text {
                            text: "MEMORY"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.memUsedText + " / " + root.memTotalText + " (" + root.memPercentText + ")"
                        color: Config.mainFg
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                // Stacked Memory Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Active App RAM (Purple)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width * root.memAppFraction
                            color: "#af52de"
                            radius: 4
                        }

                        // Cached/Buffer RAM (Teal/Cyan)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width * root.memCacheFraction
                            color: "#5ac8fa"
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // Legend / Details
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 4
                        Rectangle { width: 6; height: 6; radius: 3; color: "#af52de" }
                        Text { text: "Used " + root.memUsedText; color: Config.dimFg; font.family: Config.bodyFont; font.pixelSize: 10 }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle { width: 6; height: 6; radius: 3; color: "#5ac8fa" }
                        Text { text: "Cache " + root.memCacheText; color: Config.dimFg; font.family: Config.bodyFont; font.pixelSize: 10 }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "16 GB RAM"
                        color: Qt.rgba(1, 1, 1, 0.3)
                        font.family: Config.bodyFont
                        font.pixelSize: 9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("hyprctl dispatch exec [float] btop || missioncenter || htop")
            }
        }

        // =====================================================================
        // Panel 3: Storage (NVMe SSD)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "󰋊"
                            color: "#ff9f0a"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                        }
                        Text {
                            text: "STORAGE (NVME)"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.diskUsedText + " / " + root.diskTotalText + " (" + root.diskPercentText + ")"
                        color: Config.mainFg
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                // Storage Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * root.diskFraction
                        radius: 4
                        color: "#ff9f0a"
                    }
                }

                // NVMe Drive Status & Temperature
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Drive Temp: " + root.diskTempText
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Root (/) Mount"
                        color: Qt.rgba(1, 1, 1, 0.3)
                        font.family: Config.bodyFont
                        font.pixelSize: 9
                    }
                }
            }
        }

        // =====================================================================
        // Panel 4: Live Network Throughput
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "󰖩"
                            color: "#34c759"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                        }
                        Text {
                            text: "NETWORK"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: "↓ " + root.netDownText
                            color: "#34c759"
                            font.family: Config.monoFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "↑ " + root.netUpText
                            color: Config.dimFg
                            font.family: Config.monoFont
                            font.pixelSize: 10
                        }
                    }
                }

                // Rolling Network Traffic Canvas
                Canvas {
                    id: netCanvas
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        let pts = root.netHistory;
                        if (!pts || pts.length < 2) return;

                        let step = width / (pts.length - 1);

                        // Gradient Fill
                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        for (let i = 0; i < pts.length; i++) {
                            let y = height - (pts[i] * (height - 4));
                            ctx.lineTo(i * step, y);
                        }
                        ctx.lineTo(width, height);
                        ctx.closePath();

                        let grad = ctx.createLinearGradient(0, 0, 0, height);
                        grad.addColorStop(0, Qt.rgba(0.2, 0.78, 0.35, 0.35));
                        grad.addColorStop(1, Qt.rgba(0.2, 0.78, 0.35, 0.02));
                        ctx.fillStyle = grad;
                        ctx.fill();

                        // Waveform Line
                        ctx.beginPath();
                        for (let i = 0; i < pts.length; i++) {
                            let y = height - (pts[i] * (height - 4));
                            if (i === 0) ctx.moveTo(0, y);
                            else ctx.lineTo(i * step, y);
                        }
                        ctx.strokeStyle = "#34c759";
                        ctx.lineWidth = 2;
                        ctx.stroke();
                    }
                }
            }
        }
    }
}
