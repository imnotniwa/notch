import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"
import ".."

Item {
    id: root

    property bool compactMode: false

    implicitWidth: batContainer.implicitWidth
    implicitHeight: 24

    property int capacity: 100
    property string status: "Full"
    readonly property bool isCharging: status === "Charging"
    readonly property bool isFull: status === "Full"
    readonly property bool isDischarging: status === "Discharging" || (!isCharging && !isFull)

    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    readonly property string icon: {
        if (root.isCharging) return "󱐋";
        let idx = Math.min(Math.floor((root.capacity / 100) * (icons.length - 1)), icons.length - 1);
        return icons[Math.max(0, idx)];
    }

    readonly property color batteryColor: {
        if (root.isCharging) return Config.success;
        if (root.capacity <= 15) return Config.danger;
        if (root.capacity <= 30) return Config.warning;
        return Config.mainFg;
    }

    // Live query via Process to avoid sysfs kernel buffer caching in FileView
    Process {
        id: batQueryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/AC*/online 2>/dev/null; echo '---'; cat /sys/class/power_supply/BAT*/status 2>/dev/null; echo '---'; cat /sys/class/power_supply/BAT*/capacity 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (!raw) return;
                let sections = raw.split("---");
                if (sections.length < 3) return;

                let acVal = parseInt(sections[0].trim());
                let stat = sections[1].trim().split("\n")[0];
                let cap = parseInt(sections[2].trim().split("\n")[0]);

                if (!isNaN(cap)) root.capacity = cap;
                if (stat) root.status = stat;

                if (!isNaN(acVal)) {
                    let isPlugged = (acVal === 1);
                    if (isPlugged !== Config.lastAcOnline) {
                        Config.lastAcOnline = isPlugged;
                        Config.powerEventIcon = isPlugged ? "󱐋" : "󰂎";
                        Config.powerEventColor = isPlugged ? Config.success : Config.warning;
                        Config.powerEventMessage = isPlugged ? ("Charging " + root.capacity + "%") : ("On Battery " + root.capacity + "%");
                        Config.isPowerEventActive = true;
                        powerEventTimer.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: powerEventTimer
        interval: 3200 // Apple-standard 3.2s transient glance
        onTriggered: {
            Config.isPowerEventActive = false;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: batQueryProc.running = true
    }

    // Connect chime / transient flash when plugged in
    property bool lastCharging: false
    onIsChargingChanged: {
        if (isCharging && !lastCharging) {
            plugPulseAnim.restart();
        }
        lastCharging = isCharging;
    }

    // Transient plug connect pulse (Apple-style subtle green burst)
    SequentialAnimation {
        id: plugPulseAnim
        NumberAnimation { target: pulseGlow; property: "opacity"; to: 0.85; duration: 150; easing.type: Easing.OutQuad }
        NumberAnimation { target: pulseGlow; property: "opacity"; to: 0.0; duration: 400; easing.type: Easing.OutCubic }
    }

    // Breathing glow animation while actively charging (subtle & elegant)
    SequentialAnimation {
        id: chargingGlowLoop
        running: root.isCharging
        loops: Animation.Infinite
        NumberAnimation { target: iconText; property: "opacity"; to: 0.55; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { target: iconText; property: "opacity"; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
    }

    Rectangle {
        id: batContainer
        implicitWidth: contentRow.implicitWidth + 12
        implicitHeight: 22
        radius: 11
        Layout.alignment: Qt.AlignVCenter

        Behavior on implicitWidth {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        // Background: Subtle Apple pill with dynamic charging state
        color: root.isCharging ? Qt.rgba(Config.success.r, Config.success.g, Config.success.b, 0.16) : (batMouse.containsMouse ? Config.hvrBg : "transparent")
        border.color: root.isCharging ? Qt.rgba(Config.success.r, Config.success.g, Config.success.b, 0.35) : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // Transient connect flash ring
        Rectangle {
            id: pulseGlow
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Config.success
            border.width: 2
            opacity: 0.0
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            // Main icon: single lightning bolt when charging, battery glyph when on battery
            Text {
                id: iconText
                text: root.icon
                font.family: Config.iconFont
                font.pixelSize: 12
                color: root.batteryColor
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 180 } }
            }

            // Percentage label
            Text {
                text: root.capacity + "%"
                font.family: Config.monoFont
                font.pixelSize: 11
                font.weight: root.isCharging ? Font.Bold : Font.Normal
                color: root.batteryColor
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Clicking battery capsule switches to Hardware gallery deck
                Config.isDeckOpen = true;
                Config.galleryIndex = 2; // Hardware tab
            }
        }
    }
}
