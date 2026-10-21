import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    // Telemetry state
    property real cpuFraction: 0.0
    property string cpuUsageText: "0%"
    property string cpuTempText: "--°C"
    property var lastCpuStat: [0, 0]

    property real memFraction: 0.0
    property string memUsedText: "0.0G"
    property string memTotalText: "0.0G"
    property string memPercentText: "0%"

    property real batFraction: 1.0
    property string batStatusText: "Full"
    property bool batIsCharging: false
    property string batWattageText: ""

    property real diskFraction: 0.0
    property string diskUsedText: "0.0G"
    property string diskTotalText: "0.0G"
    property string diskPercentText: "0%"

    // Sysfs /proc FileViews
    FileView {
        id: procStat
        path: "/proc/stat"
    }

    FileView {
        id: procMem
        path: "/proc/meminfo"
    }

    FileView {
        id: thermalZone
        path: "/sys/class/thermal/thermal_zone0/temp"
    }

    // Live sysfs battery process query to prevent virtual filesystem caching
    Process {
        id: batQueryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; echo '---'; cat /sys/class/power_supply/BAT*/status 2>/dev/null; echo '---'; cat /sys/class/power_supply/BAT*/power_now 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (!raw) return;
                let sections = raw.split("---");
                if (sections.length < 3) return;

                let cap = parseInt(sections[0].trim().split("\n")[0]);
                let stat = sections[1].trim().split("\n")[0];
                let pwr = parseInt(sections[2].trim().split("\n")[0]);

                if (!isNaN(cap)) {
                    root.batFraction = Math.max(0, Math.min(1, cap / 100));
                }
                if (stat) {
                    root.batStatusText = stat;
                    root.batIsCharging = (stat === "Charging");
                }
                if (!isNaN(pwr) && pwr > 0) {
                    let watts = (pwr / 1000000).toFixed(1);
                    root.batWattageText = watts + "W";
                } else {
                    root.batWattageText = "";
                }
            }
        }
    }

    // Process for disk space calculation
    Process {
        id: diskProc
        command: ["sh", "-c", "df -m / | awk 'NR==2 {print $3, $2, $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parts = this.text.trim().split(/\s+/);
                    if (parts.length >= 3) {
                        let usedMb = parseInt(parts[0]);
                        let totalMb = parseInt(parts[1]);
                        let pct = parts[2];
                        root.diskUsedText = (usedMb / 1024).toFixed(1) + "G";
                        root.diskTotalText = (totalMb / 1024).toFixed(1) + "G";
                        root.diskPercentText = pct;
                        root.diskFraction = totalMb > 0 ? (usedMb / totalMb) : 0;
                    }
                } catch (e) {}
            }
        }
    }

    // hyde-shell cpuinfo fallback for temperature if thermalZone isn't readable
    Process {
        id: cpuInfoProc
        command: ["hyde-shell", "cpuinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    if (res && res.text) root.cpuTempText = res.text;
                } catch (e) {}
            }
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
                let frac = Math.max(0, Math.min(1, (diffTotal - diffIdle) / diffTotal));
                root.cpuFraction = frac;
                root.cpuUsageText = Math.round(frac * 100) + "%";
            }
        }
        root.lastCpuStat = [idle, total];

        // Temp
        let tempRaw = thermalZone.text().trim();
        if (tempRaw) {
            let deg = Math.round(parseInt(tempRaw) / 1000);
            if (!isNaN(deg) && deg > 0) {
                root.cpuTempText = deg + "°C";
            }
        } else {
            cpuInfoProc.running = true;
        }
    }

    function updateMem() {
        let text = procMem.text();
        if (!text) return;
        let totalKb = 0;
        let availKb = 0;
        let lines = text.split("\n");
        for (let i = 0; i < lines.length && i < 6; i++) {
            let l = lines[i];
            if (l.startsWith("MemTotal:")) totalKb = parseInt(l.replace(/\D/g, ''));
            if (l.startsWith("MemAvailable:")) availKb = parseInt(l.replace(/\D/g, ''));
        }
        if (totalKb > 0) {
            let usedKb = totalKb - availKb;
            let frac = Math.max(0, Math.min(1, usedKb / totalKb));
            root.memFraction = frac;
            root.memUsedText = (usedKb / 1048576).toFixed(1) + "G";
            root.memTotalText = (totalKb / 1048576).toFixed(1) + "G";
            root.memPercentText = Math.round(frac * 100) + "%";
        }
    }

    function updateBattery() {
        batQueryProc.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: Config.expanded && Config.galleryIndex === 2
        triggeredOnStart: true
        onTriggered: {
            root.updateCpu();
            root.updateMem();
            root.updateBattery();
            diskProc.running = true;
        }
    }

    Component.onCompleted: {
        root.updateCpu();
        root.updateMem();
        root.updateBattery();
        diskProc.running = true;
    }

    // 2x2 Grid Layout
    GridLayout {
        anchors.fill: parent
        columns: 2
        columnSpacing: 10
        rowSpacing: 8

        // =====================================================================
        // Card 1: CPU & Temperature
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("hyprctl dispatch exec [float] btop || missioncenter || htop")
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰍛"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: Config.mainFg
                        }
                        Text {
                            text: "CPU"
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Config.mainFg
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Temperature badge
                    Rectangle {
                        implicitHeight: 16
                        implicitWidth: tempLabel.implicitWidth + 8
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: tempLabel
                            anchors.centerIn: parent
                            text: root.cpuTempText
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: {
                                let deg = parseInt(root.cpuTempText);
                                if (!isNaN(deg)) {
                                    if (deg >= 85) return Config.danger;
                                    if (deg >= 72) return Config.warning;
                                }
                                return Qt.rgba(1, 1, 1, 0.75);
                            }
                        }
                    }

                    Text {
                        text: root.cpuUsageText
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Config.mainFg
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(4, parent.width * root.cpuFraction)
                        radius: 2.5
                        color: {
                            if (root.cpuFraction >= 0.85) return Config.danger;
                            if (root.cpuFraction >= 0.65) return Config.warning;
                            return Config.actFg;
                        }

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Card 2: Memory & Swap
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("hyprctl dispatch exec [float] btop || missioncenter || htop")
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰾆"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: Config.mainFg
                        }
                        Text {
                            text: "RAM"
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Config.mainFg
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.memUsedText + " / " + root.memTotalText
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }

                    Text {
                        text: root.memPercentText
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Config.mainFg
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(4, parent.width * root.memFraction)
                        radius: 2.5
                        color: {
                            if (root.memFraction >= 0.90) return Config.danger;
                            if (root.memFraction >= 0.75) return Config.warning;
                            return Config.actFg;
                        }

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Card 3: Battery & Power
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 5
                        Text {
                            text: root.batIsCharging ? "󱐋" : (root.batFraction <= 0.15 ? "󰂎" : (root.batFraction <= 0.5 ? "󰁾" : "󰁹"))
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: root.batIsCharging ? Config.success : (root.batFraction <= 0.15 ? Config.danger : Config.mainFg)

                            // Subtle breathing pulse on the lightning bolt while charging
                            SequentialAnimation on opacity {
                                running: root.batIsCharging
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }
                        Text {
                            text: "Battery"
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Config.mainFg
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: (root.batWattageText !== "" ? (root.batWattageText + " • ") : "") + root.batStatusText
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        color: root.batIsCharging ? Config.success : Qt.rgba(1, 1, 1, 0.6)
                    }

                    Text {
                        text: Math.round(root.batFraction * 100) + "%"
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.batIsCharging ? Config.success : Config.mainFg
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(4, parent.width * root.batFraction)
                        radius: 2.5
                        color: {
                            if (root.batIsCharging) return Config.success;
                            if (root.batFraction <= 0.15) return Config.danger;
                            if (root.batFraction <= 0.30) return Config.warning;
                            return Config.success;
                        }

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Card 4: Storage & Disk
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("hyprctl dispatch exec [float] baobab || nautilus ~ || thunar ~")
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰋊"
                            font.family: Config.iconFont
                            font.pixelSize: 13
                            color: Config.mainFg
                        }
                        Text {
                            text: "Storage"
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Config.mainFg
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.diskUsedText + " / " + root.diskTotalText
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }

                    Text {
                        text: root.diskPercentText !== "" ? root.diskPercentText : (Math.round(root.diskFraction * 100) + "%")
                        font.family: Config.monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Config.mainFg
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 2.5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(4, parent.width * root.diskFraction)
                        radius: 2.5
                        color: {
                            if (root.diskFraction >= 0.90) return Config.danger;
                            if (root.diskFraction >= 0.75) return Config.warning;
                            return Config.actFg;
                        }

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
