import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    property bool compactMode: false

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property int capacity: 100
    property string status: "Full"
    readonly property bool isCharging: status === "Charging"
    readonly property bool isFull: status === "Full"
    readonly property bool isDischarging: status === "Discharging" || (!isCharging && !isFull)

    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    readonly property string icon: {
        if (root.isCharging) return "";
        let idx = Math.min(Math.floor((root.capacity / 100) * (icons.length - 1)), icons.length - 1);
        return icons[Math.max(0, idx)];
    }

    readonly property color batteryColor: {
        if (root.capacity <= 15) return Config.danger;
        if (root.capacity <= 30) return Config.warning;
        if (root.isCharging) return Config.actFg;
        return Config.mainFg;
    }

    FileView {
        id: batCap
        path: "/sys/class/power_supply/BAT0/capacity"
    }

    FileView {
        id: batStat
        path: "/sys/class/power_supply/BAT0/status"
    }

    function refreshBattery() {
        let cap = parseInt(batCap.text().trim());
        let stat = batStat.text().trim();
        if (!isNaN(cap)) root.capacity = cap;
        if (stat) root.status = stat;
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshBattery()
    }

    IslandButton {
        id: btn
        icon: root.icon
        // In compact mode: always show percentage if not charged / discharging
        text: (root.compactMode ? (root.isDischarging ? root.capacity + "%" : "") : root.capacity + "%")
        textColor: root.batteryColor
        tooltip: "Battery: " + root.capacity + "% (" + root.status + ")"
    }
}
