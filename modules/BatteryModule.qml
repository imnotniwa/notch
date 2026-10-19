import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property int capacity: 100
    property string status: "Full"
    property bool isCharging: status === "Charging"

    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    readonly property string icon: {
        if (root.isCharging) return "";
        let idx = Math.min(Math.floor((root.capacity / 100) * (icons.length - 1)), icons.length - 1);
        return icons[Math.max(0, idx)];
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
        text: root.capacity + "%"
        tooltip: "Battery: " + root.capacity + "% (" + root.status + ")"
    }
}
