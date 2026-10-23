import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    // =========================================================================
    // Pipewire Audio Telemetry & Controls
    // =========================================================================
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volumeFrac: sink && sink.audio ? Math.max(0.0, Math.min(1.5, sink.audio.volume)) : 0.5
    readonly property int volumePct: Math.round(volumeFrac * 100)

    readonly property string sinkIcon: {
        if (root.isMuted) return "󰖁";
        if (root.volumePct > 60) return "";
        if (root.volumePct > 25) return "";
        return "";
    }

    function setVolumeFrac(val) {
        let clamped = Math.max(0.0, Math.min(1.0, val));
        if (root.sink && root.sink.audio) {
            root.sink.audio.volume = clamped;
            if (root.isMuted) {
                root.sink.audio.muted = false;
            }
        }
    }

    // =========================================================================
    // Brightness Telemetry & Controls
    // =========================================================================
    property int brightnessPct: 50

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

    function setBrightness(pct) {
        let clamped = Math.max(5, Math.min(100, Math.round(pct)));
        root.brightnessPct = clamped;
        Config.run("brightnessctl set " + clamped + "%");
    }

    // =========================================================================
    // Wi-Fi Telemetry & Controls
    // =========================================================================
    property string wifiSsid: "Wi-Fi"
    property bool wifiConnected: true

    Process {
        id: ssidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = this.text.trim();
                root.wifiConnected = (name !== "");
                root.wifiSsid = name !== "" ? name : "Disconnected";
            }
        }
    }

    // =========================================================================
    // Bluetooth Telemetry & Controls
    // =========================================================================
    property bool btPowered: false
    property string btDeviceName: ""

    Process {
        id: btStatusProc
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.btPowered = (this.text.trim() === "on");
            }
        }
    }

    Process {
        id: btDeviceProc
        command: ["sh", "-c", "bluetoothctl info 2>/dev/null | grep 'Alias:' | cut -d: -f2 | xargs"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.btDeviceName = this.text.trim();
            }
        }
    }

    // =========================================================================
    // Caffeine (Keep Awake)
    // =========================================================================
    property bool caffeineActive: false

    Process {
        id: caffeineStatusProc
        command: ["sh", "-c", "hyde-shell caffeine -rq 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let res = JSON.parse(this.text.trim());
                    root.caffeineActive = (res && res.class === "activated");
                } catch (e) {}
            }
        }
    }

    // =========================================================================
    // Night Light (hyprsunset)
    // =========================================================================
    property bool nightLightActive: false

    Process {
        id: nightLightCheckProc
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo 'on' || echo 'off'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLightActive = (this.text.trim() === "on");
            }
        }
    }

    // High frequency sync timer
    Timer {
        interval: 2500
        repeat: true
        running: Config.expanded && Config.galleryIndex === 4
        triggeredOnStart: true
        onTriggered: {
            root.refreshBrightness();
            ssidProc.running = true;
            btStatusProc.running = true;
            btDeviceProc.running = true;
            caffeineStatusProc.running = true;
            nightLightCheckProc.running = true;
        }
    }

    Component.onCompleted: {
        root.refreshBrightness();
        ssidProc.running = true;
        btStatusProc.running = true;
        btDeviceProc.running = true;
        caffeineStatusProc.running = true;
        nightLightCheckProc.running = true;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // =====================================================================
        // LEFT SIDE: Wide Scrubber Sliders (Brightness & Volume)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 330
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Section Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "SYSTEM SLIDERS"
                    color: Config.dimFg
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Item { Layout.fillWidth: true }
            }

            // 1. Display Brightness Slider Box
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰃠"
                            color: "#ff9f0a"
                            font.family: Config.iconFont
                            font.pixelSize: 15
                        }

                        Text {
                            text: "Display Brightness"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: brightVal.implicitWidth + 12
                            implicitHeight: 20
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                id: brightVal
                                anchors.centerIn: parent
                                text: root.brightnessPct + "%"
                                color: Config.mainFg
                                font.family: Config.monoFont
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Brightness Pill Slider Track (supports click, drag, and scroll wheel)
                    Rectangle {
                        id: brightTrack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.brightnessPct / 100.0)))
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ff9f0a" }
                                GradientStop { position: 1.0; color: "#ffd60a" }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            function updateFromPos(mouseX) {
                                let pct = (mouseX / width) * 100;
                                root.setBrightness(pct);
                            }

                            onPressed: (mouse) => updateFromPos(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    updateFromPos(mouse.x);
                                }
                            }
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) {
                                    root.setBrightness(root.brightnessPct + 5);
                                } else if (wheel.angleDelta.y < 0) {
                                    root.setBrightness(root.brightnessPct - 5);
                                }
                            }
                        }
                    }
                }
            }

            // 2. Sound Volume Slider Box
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Mute button icon
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: volMuteM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.sinkIcon
                                color: root.isMuted ? Config.danger : Config.actBg
                                font.family: Config.iconFont
                                font.pixelSize: 15
                            }

                            MouseArea {
                                id: volMuteM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                            }
                        }

                        Text {
                            text: "Sound Volume"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: volVal.implicitWidth + 12
                            implicitHeight: 20
                            radius: 10
                            color: root.isMuted ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.25) : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                id: volVal
                                anchors.centerIn: parent
                                text: root.isMuted ? "Muted" : (root.volumePct + "%")
                                color: root.isMuted ? Config.danger : Config.mainFg
                                font.family: Config.monoFont
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Volume Pill Slider Track (supports click, drag, and scroll wheel)
                    Rectangle {
                        id: volTrack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.08)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * Math.min(1.0, root.volumeFrac)))
                            radius: parent.radius
                            color: root.isMuted ? Config.dimFg : Config.actBg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            function updateFromPos(mouseX) {
                                let frac = mouseX / width;
                                root.setVolumeFrac(frac);
                            }

                            onPressed: (mouse) => updateFromPos(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    updateFromPos(mouse.x);
                                }
                            }
                            onWheel: (wheel) => {
                                let step = 0.05;
                                if (wheel.angleDelta.y > 0) {
                                    root.setVolumeFrac(root.volumeFrac + step);
                                } else if (wheel.angleDelta.y < 0) {
                                    root.setVolumeFrac(root.volumeFrac - step);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Vertical Divider
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // =====================================================================
        // RIGHT SIDE: 2×2 Toggles Matrix (Wi-Fi, Bluetooth, Caffeine, Night Light)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "QUICK TOGGLES"
                color: Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // 1. Wi-Fi Toggle & Manager
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: root.wifiConnected ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.20) : (wifiMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: root.wifiConnected ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.45) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: root.wifiConnected ? "󰖩" : "󰖪"
                                color: root.wifiConnected ? Config.actBg : Config.dimFg
                                font.family: Config.iconFont
                                font.pixelSize: 18
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "󰒓"
                                color: Qt.rgba(1, 1, 1, 0.3)
                                font.family: Config.iconFont
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Wi-Fi"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.wifiSsid
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                // Right-click: launch GUI connection manager
                                Config.run("nm-connection-editor || kitty -e nmtui");
                            } else {
                                // Left-click: toggle radio power on/off
                                Config.run("rfkill toggle wifi || nmcli radio wifi " + (root.wifiConnected ? "off" : "on"));
                                root.wifiConnected = !root.wifiConnected;
                                if (!root.wifiConnected) root.wifiSsid = "Disconnected";
                                wifiRefreshTimer.start();
                            }
                        }
                        onDoubleClicked: {
                            Config.run("nm-connection-editor || kitty -e nmtui");
                        }
                    }

                    Timer {
                        id: wifiRefreshTimer
                        interval: 800
                        onTriggered: ssidProc.running = true
                    }
                }

                // 2. Bluetooth Toggle & Manager
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: root.btPowered ? Qt.rgba(0.2, 0.5, 1.0, 0.20) : (btMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: root.btPowered ? Qt.rgba(0.2, 0.5, 1.0, 0.45) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: root.btPowered ? "󰂯" : "󰂲"
                                color: root.btPowered ? "#0071e3" : Config.dimFg
                                font.family: Config.iconFont
                                font.pixelSize: 18
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "󰒓"
                                color: Qt.rgba(1, 1, 1, 0.3)
                                font.family: Config.iconFont
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Bluetooth"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.btDeviceName !== "" ? root.btDeviceName : (root.btPowered ? "On" : "Off")
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                HyprlandLua.openBluetoothManager();
                            } else {
                                if (root.btPowered) {
                                    Config.run("bluetoothctl power off");
                                    root.btPowered = false;
                                } else {
                                    Config.run("bluetoothctl power on");
                                    root.btPowered = true;
                                }
                                btRefreshTimer.start();
                            }
                        }
                        onDoubleClicked: {
                            HyprlandLua.openBluetoothManager();
                        }
                    }

                    Timer {
                        id: btRefreshTimer
                        interval: 500
                        onTriggered: {
                            btStatusProc.running = true;
                            btDeviceProc.running = true;
                        }
                    }
                }

                // 3. Caffeine (Keep Awake) Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: root.caffeineActive ? Qt.rgba(0.95, 0.61, 0.07, 0.20) : (cafMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: root.caffeineActive ? Qt.rgba(0.95, 0.61, 0.07, 0.45) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text {
                            text: root.caffeineActive ? "󰅶" : "󰛊"
                            color: root.caffeineActive ? "#f39c12" : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 18
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Caffeine"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.caffeineActive ? "Active" : "Disabled"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: cafMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.run("hyde-shell caffeine -t -P waybar,21");
                            root.caffeineActive = !root.caffeineActive;
                            cafRefreshTimer.start();
                        }
                    }

                    Timer {
                        id: cafRefreshTimer
                        interval: 600
                        onTriggered: caffeineStatusProc.running = true
                    }
                }

                // 4. Night Light (hyprsunset) Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: root.nightLightActive ? Qt.rgba(0.68, 0.32, 0.87, 0.20) : (nlMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: root.nightLightActive ? Qt.rgba(0.68, 0.32, 0.87, 0.45) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text {
                            text: root.nightLightActive ? "󰌌" : "󰌌"
                            color: root.nightLightActive ? "#af52de" : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 18
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Night Light"
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.nightLightActive ? "Warm (Active)" : "Off"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: nlMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.nightLightActive) {
                                Config.run("pkill hyprsunset || true");
                                root.nightLightActive = false;
                            } else {
                                Config.run("hyprsunset -t 4500 &");
                                root.nightLightActive = true;
                            }
                            nlRefreshTimer.start();
                        }
                    }

                    Timer {
                        id: nlRefreshTimer
                        interval: 600
                        onTriggered: nightLightCheckProc.running = true
                    }
                }
            }
        }
    }
}
