import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import ".."

Item {
    id: root

    property bool compactMode: false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volumePct: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    readonly property string sinkIcon: {
        if (root.isMuted) return "󰖁";
        if (root.volumePct > 60) return "";
        if (root.volumePct > 25) return "";
        return "";
    }

    readonly property string micIcon: root.micMuted ? "" : ""

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        // Audio Output Button
        IslandButton {
            icon: root.sinkIcon
            text: root.volumePct + "%"
            tooltip: root.compactMode ? "" : ((root.isMuted ? "Muted" : "Volume: " + root.volumePct + "%") + " (Scroll: Adjust, Click: Pavucontrol, Middle: Mute)")
            isMonoFont: true

            onClicked: {
                if (!root.compactMode) {
                    Config.run("pavucontrol || pavucontrol-qt");
                }
            }
            onMiddleClicked: {
                if (!root.compactMode) {
                    Config.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
                }
            }
            onScrolledUp: {
                if (!root.compactMode) {
                    Config.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+");
                }
            }
            onScrolledDown: {
                if (!root.compactMode) {
                    Config.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-");
                }
            }
        }

        // Microphone Button
        IslandButton {
            visible: !root.compactMode
            icon: root.micIcon
            tooltip: (root.micMuted ? "Mic Muted" : "Mic Active") + " (Middle: Mute toggle, Scroll: Gain)"
            active: root.micMuted
            onMiddleClicked: {
                Config.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle");
            }
            onScrolledUp: {
                Config.run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SOURCE@ 5%+");
            }
            onScrolledDown: {
                Config.run("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-");
            }
        }
    }
}
