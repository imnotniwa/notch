pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Item {
    id: root

    // OSD Types: "volume" | "brightness"
    property string currentType: ""
    property real currentValue: 0.0 // 0.0 to 1.0
    property string currentIcon: ""
    property string currentLabel: "Volume"
    property bool currentMuted: false
    property bool isOsdVisible: false

    // Auto-hide timer for OSD capsule
    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: {
            root.isOsdVisible = false;
        }
    }

    function triggerOsd(type, value, icon, label, muted) {
        root.currentType = type;
        root.currentValue = Math.max(0.0, Math.min(1.0, value));
        root.currentIcon = icon;
        root.currentLabel = label;
        root.currentMuted = !!muted;
        root.isOsdVisible = true;
        hideTimer.restart();
    }

    // =========================================================================
    // Pipewire Audio Monitoring
    // =========================================================================
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    property real lastVolume: -1
    property bool lastMuted: false
    property bool audioInitialized: false

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null

        function onVolumeChanged() {
            if (!root.sink || !root.sink.audio) return;
            let curVol = root.sink.audio.volume;
            if (!root.audioInitialized) {
                root.lastVolume = curVol;
                root.audioInitialized = true;
                return;
            }

            // Only trigger if volume actually shifted by noticeable amount
            if (Math.abs(curVol - root.lastVolume) > 0.005) {
                root.lastVolume = curVol;
                let volFrac = Math.max(0.0, Math.min(1.0, curVol));
                let icon = "";
                if (root.sink.audio.muted) icon = "󰖁";
                else if (volFrac > 0.6) icon = "";
                else if (volFrac > 0.25) icon = "";
                else icon = "";

                root.triggerOsd("volume", volFrac, icon, "Volume", root.sink.audio.muted);
            }
        }

        function onMutedChanged() {
            if (!root.sink || !root.sink.audio) return;
            let curMuted = root.sink.audio.muted;
            if (!root.audioInitialized) {
                root.lastMuted = curMuted;
                root.audioInitialized = true;
                return;
            }

            if (curMuted !== root.lastMuted) {
                root.lastMuted = curMuted;
                let volFrac = Math.max(0.0, Math.min(1.0, root.sink.audio.volume));
                let icon = curMuted ? "󰖁" : (volFrac > 0.6 ? "" : (volFrac > 0.25 ? "" : ""));
                root.triggerOsd("volume", volFrac, icon, curMuted ? "Muted" : "Volume", curMuted);
            }
        }
    }

    // =========================================================================
    // Brightness Monitoring via sysfs
    // =========================================================================
    FileView {
        id: actualBrightness
        path: "/sys/class/backlight/intel_backlight/actual_brightness"
    }

    FileView {
        id: maxBrightness
        path: "/sys/class/backlight/intel_backlight/max_brightness"
    }

    property real lastBrightness: -1
    property bool brightnessInitialized: false

    Timer {
        id: brightnessPoller
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            let cur = parseInt(actualBrightness.text().trim());
            let max = parseInt(maxBrightness.text().trim());
            if (isNaN(cur) || isNaN(max) || max <= 0) return;

            let frac = cur / max;
            if (!root.brightnessInitialized) {
                root.lastBrightness = frac;
                root.brightnessInitialized = true;
                return;
            }

            if (Math.abs(frac - root.lastBrightness) > 0.01) {
                root.lastBrightness = frac;
                root.triggerOsd("brightness", frac, "󰃠", "Brightness", false);
            }
        }
    }
}
