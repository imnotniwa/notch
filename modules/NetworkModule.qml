import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property string icon: "󰤨"
    property string ssid: "Connecting..."
    property bool isConnected: true

    FileView {
        id: wlanOper
        path: "/sys/class/net/wlan0/operstate"
    }

    Process {
        id: ssidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = this.text.trim();
                root.ssid = name !== "" ? name : "Wi-Fi";
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            let state = wlanOper.text().trim();
            root.isConnected = (state === "up");
            if (root.isConnected) {
                ssidProc.running = true;
                root.icon = "󰤨";
            } else {
                root.icon = "󰤭";
                root.ssid = "Disconnected";
            }
        }
    }

    IslandButton {
        id: btn
        icon: root.icon
        tooltip: root.isConnected ? "Connected to " + root.ssid : "Network Disconnected"
    }
}
