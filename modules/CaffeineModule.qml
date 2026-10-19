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

    property string icon: "󰛊"
    property string tip: "Caffeine"
    property bool active: false

    Process {
        id: caffeineProc
        command: ["hyde-shell", "caffeine", "-rq"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    if (res && res.text) root.icon = res.text;
                    if (res && res.tooltip) root.tip = res.tooltip.replace(/<[^>]*>/g, '');
                    root.active = (res && res.class === "activated");
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            caffeineProc.running = true;
        }
    }

    IslandButton {
        id: btn
        icon: root.icon
        tooltip: root.tip
        active: root.active
        onClicked: {
            Config.run("hyde-shell caffeine -t -P waybar,21");
            refreshTimer.start();
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: caffeineProc.running = true
    }
}
