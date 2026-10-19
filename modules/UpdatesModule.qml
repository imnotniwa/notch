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

    property string text: ""
    property string tip: "System Updates"

    Process {
        id: updateProc
        command: ["hyde-shell", "system.update"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    if (res && res.text) root.text = res.text;
                    if (res && res.tooltip) root.tip = res.tooltip;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 300000 // 5 minutes
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: updateProc.running = true
    }

    IslandButton {
        id: btn
        visible: root.text !== ""
        text: root.text
        tooltip: root.tip + " (Click to upgrade)"
        onClicked: {
            Hyprland.dispatch("exec hyde-shell system.update up");
        }
    }
}
