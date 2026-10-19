import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../components"
import ".."

Item {
    id: root

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property int brightnessPct: 50
    readonly property var icons: ["", "", "", "", "", "", "", "", ""]

    readonly property string icon: {
        let idx = Math.min(Math.floor((brightnessPct / 100) * icons.length), icons.length - 1);
        return icons[Math.max(0, idx)];
    }

    FileView {
        id: actualBrightness
        path: "/sys/class/backlight/intel_backlight/actual_brightness"
    }

    FileView {
        id: maxBrightness
        path: "/sys/class/backlight/intel_backlight/max_brightness"
    }

    function refreshBrightness() {
        let cur = parseInt(actualBrightness.text().trim());
        let max = parseInt(maxBrightness.text().trim());
        if (!isNaN(cur) && !isNaN(max) && max > 0) {
            root.brightnessPct = Math.round((cur / max) * 100);
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshBrightness()
    }

    IslandButton {
        id: btn
        icon: root.icon
        text: root.brightnessPct + "%"
        tooltip: "Brightness: " + root.brightnessPct + "% (Scroll to adjust)"

        onScrolledUp: {
            Config.run("brightnessctl set +5%");
            refreshTimer.start();
        }
        onScrolledDown: {
            Config.run("brightnessctl set 5%-");
            refreshTimer.start();
        }
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: root.refreshBrightness()
    }
}
