import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import "../components"
import ".."

Item {
    id: root

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
            tooltip: (root.isMuted ? "Muted" : "Volume: " + root.volumePct + "%") + " (Scroll: Adjust, Click: Pavucontrol, Middle: Mute)"

            onClicked: {
                Hyprland.dispatch("exec pavucontrol-qt -t 3 || pavucontrol -t 3");
            }
            onRightClicked: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -s ''");
            }
            onMiddleClicked: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -o m");
            }
            onScrolledUp: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -o i");
            }
            onScrolledDown: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -o d");
            }
        }

        // Microphone Button
        IslandButton {
            icon: root.micIcon
            tooltip: (root.micMuted ? "Mic Muted" : "Mic Active") + " (Middle: Mute toggle)"
            active: root.micMuted
            onMiddleClicked: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -i m");
            }
            onScrolledUp: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -i i");
            }
            onScrolledDown: {
                Hyprland.dispatch("exec hyde-shell volumecontrol -i d");
            }
        }
    }
}
