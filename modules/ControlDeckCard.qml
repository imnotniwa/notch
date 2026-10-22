import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    // =========================================================================
    // Telemetry: Audio (Pipewire)
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

    // =========================================================================
    // Telemetry: Brightness
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

    // =========================================================================
    // Telemetry: Wi-Fi
    // =========================================================================
    property string wifiSsid: "Wi-Fi"
    property bool wifiConnected: true

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
                root.wifiSsid = name !== "" ? name : "Wi-Fi";
            }
        }
    }

    // =========================================================================
    // Telemetry: Bluetooth
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

    // Hyprsunset state
    property bool sunsetActive: false

    function refreshAll() {
        root.refreshBrightness();
        
        let state = wlanOper.text().trim();
        root.wifiConnected = (state === "up");
        if (root.wifiConnected) {
            ssidProc.running = true;
        } else {
            root.wifiSsid = "Disconnected";
        }

        btStatusProc.running = true;
        btDeviceProc.running = true;
    }

    Timer {
        interval: 3000
        repeat: true
        running: Config.expanded && Config.galleryIndex === 3
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    Component.onCompleted: {
        root.refreshAll();
    }

    // Adjustment helpers
    function adjustVolume(delta) {
        if (delta > 0) {
            Config.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + delta + "%+");
        } else {
            Config.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.abs(delta) + "%-");
        }
    }

    function setVolume(frac) {
        Config.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + frac.toFixed(2));
    }

    function adjustBrightness(delta) {
        if (delta > 0) {
            Config.run("brightnessctl set +" + delta + "%");
        } else {
            Config.run("brightnessctl set " + Math.abs(delta) + "%-");
        }
        root.refreshBrightness();
    }

    function setBrightness(pct) {
        root.brightnessPct = pct;
        Config.run("brightnessctl set " + pct + "%");
    }

    // =========================================================================
    // 2x2 Grid Layout with strict sizing and zero clipping
    // Total slot: 520px x 96px (2 columns x 2 rows, cards: 255px x 44px)
    // =========================================================================
    GridLayout {
        anchors.fill: parent
        columns: 2
        columnSpacing: 10
        rowSpacing: 8

        // =====================================================================
        // Card 1: Audio Volume (Top-Left)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 3

                // Header line: Speaker Icon + Volume + Percentage
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 4
                        color: muteMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: root.sinkIcon
                            font.family: Config.iconFont
                            font.pixelSize: 11
                            color: root.isMuted ? Config.danger : Config.mainFg
                        }

                        MouseArea {
                            id: muteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                        }
                    }

                    Text {
                        text: "Volume"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.isMuted ? "Muted" : (root.volumePct + "%")
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.isMuted ? Config.danger : Config.mainFg
                    }
                }

                // Preset Buttons Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: root.isMuted ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.25) : (btnMuteM.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))
                        border.color: root.isMuted ? Config.danger : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Mute"
                            font.family: Config.bodyFont
                            font.pixelSize: 8
                            color: root.isMuted ? Config.danger : Config.mainFg
                        }

                        MouseArea {
                            id: btnMuteM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (!root.isMuted && Math.abs(root.volumePct - 25) <= 3) ? Config.actBg : (btn25M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "25%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (!root.isMuted && Math.abs(root.volumePct - 25) <= 3) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: btn25M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setVolume(0.25)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (!root.isMuted && Math.abs(root.volumePct - 50) <= 3) ? Config.actBg : (btn50M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "50%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (!root.isMuted && Math.abs(root.volumePct - 50) <= 3) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: btn50M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setVolume(0.50)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (!root.isMuted && Math.abs(root.volumePct - 80) <= 3) ? Config.actBg : (btn80M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "80%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (!root.isMuted && Math.abs(root.volumePct - 80) <= 3) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: btn80M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setVolume(0.80)
                        }
                    }

                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 4
                        color: btnPlusM.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.family: Config.monoFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Config.mainFg
                        }

                        MouseArea {
                            id: btnPlusM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.run("pavucontrol || pavucontrol-qt")
                        }
                    }
                }
            }

            // Scroll wheel over card to adjust
            MouseArea {
                anchors.fill: parent
                z: -1
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) root.adjustVolume(5);
                    else root.adjustVolume(-5);
                }
            }
        }

        // =====================================================================
        // Card 2: Wi-Fi Card (Top-Right)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 10
            color: wifiMouse.containsMouse ? Config.hvrBg : Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: root.wifiConnected ? "󰤨" : "󰤭"
                    font.family: Config.iconFont
                    font.pixelSize: 14
                    color: root.wifiConnected ? Config.actFg : Qt.rgba(1, 1, 1, 0.4)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        text: "Wi-Fi"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Text {
                        text: root.wifiConnected ? root.wifiSsid : "Disconnected"
                        font.family: Config.bodyFont
                        font.pixelSize: 9
                        color: Qt.rgba(1, 1, 1, 0.5)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "󰒓"
                    font.family: Config.iconFont
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.25)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.run("nm-connection-editor || nmtui || nm-applet")
            }
        }

        // =====================================================================
        // Card 3: Display Brightness (Bottom-Left)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 3

                // Header line: Sun Icon + Display + Percentage
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "󰃠"
                        font.family: Config.iconFont
                        font.pixelSize: 11
                        color: Config.mainFg
                    }

                    Text {
                        text: "Display"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.brightnessPct + "%"
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Config.mainFg
                    }
                }

                // Preset Buttons Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (Math.abs(root.brightnessPct - 10) <= 5) ? Config.actBg : (bMinM.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "Min"
                            font.family: Config.bodyFont
                            font.pixelSize: 8
                            color: (Math.abs(root.brightnessPct - 10) <= 5) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: bMinM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightness(10)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (Math.abs(root.brightnessPct - 25) <= 5) ? Config.actBg : (b25M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "25%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (Math.abs(root.brightnessPct - 25) <= 5) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: b25M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightness(25)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (Math.abs(root.brightnessPct - 50) <= 5) ? Config.actBg : (b50M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "50%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (Math.abs(root.brightnessPct - 50) <= 5) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: b50M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightness(50)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (Math.abs(root.brightnessPct - 75) <= 5) ? Config.actBg : (b75M.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "75%"
                            font.family: Config.monoFont
                            font.pixelSize: 8
                            color: (Math.abs(root.brightnessPct - 75) <= 5) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: b75M
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightness(75)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 4
                        color: (root.brightnessPct >= 95) ? Config.actBg : (bMaxM.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06))

                        Text {
                            anchors.centerIn: parent
                            text: "Max"
                            font.family: Config.bodyFont
                            font.pixelSize: 8
                            color: (root.brightnessPct >= 95) ? Config.actFg : Config.mainFg
                        }

                        MouseArea {
                            id: bMaxM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightness(100)
                        }
                    }
                }
            }

            // Scroll wheel over card to adjust
            MouseArea {
                anchors.fill: parent
                z: -1
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) root.adjustBrightness(5);
                    else root.adjustBrightness(-5);
                }
            }
        }

        // =====================================================================
        // Card 4: Bluetooth (Bottom-Right) - Dedicated Full Card matching Wi-Fi
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 10
            color: btMouse.containsMouse ? Config.hvrBg : Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: root.btPowered ? "󰂯" : "󰂲"
                    font.family: Config.iconFont
                    font.pixelSize: 14
                    color: root.btPowered ? Config.actFg : Qt.rgba(1, 1, 1, 0.4)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    Text {
                        text: "Bluetooth"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Text {
                        text: root.btPowered ? (root.btDeviceName !== "" ? root.btDeviceName : "Enabled") : "Disabled"
                        font.family: Config.bodyFont
                        font.pixelSize: 9
                        color: Qt.rgba(1, 1, 1, 0.5)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "󰒓"
                    font.family: Config.iconFont
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.25)
                    Layout.alignment: Qt.AlignVCenter
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
                        HyprlandLua.toggleBluetooth();
                        btTimer.start();
                    }
                }
                onDoubleClicked: {
                    HyprlandLua.openBluetoothManager();
                }
            }

            Timer {
                id: btTimer
                interval: 400
                onTriggered: {
                    btStatusProc.running = true;
                    btDeviceProc.running = true;
                }
            }
        }
    }
}
