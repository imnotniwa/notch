import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import ".."

Item {
    id: root

    // Find the first active player (or first playing player)
    readonly property var activePlayer: {
        if (!Mpris.players || Mpris.players.values.length === 0) return null;
        for (let i = 0; i < Mpris.players.values.length; i++) {
            let p = Mpris.players.values[i];
            if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        return Mpris.players.values[0];
    }

    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "Media") : ""
    readonly property string artist: {
        if (!activePlayer || !activePlayer.trackArtists) return "";
        if (Array.isArray(activePlayer.trackArtists)) return activePlayer.trackArtists.join(", ");
        return activePlayer.trackArtists.toString();
    }

    implicitWidth: hasMedia ? contentRow.implicitWidth + 16 : 0
    implicitHeight: 28
    visible: hasMedia

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // Music icon or album art
        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: root.isPlaying ? Config.actBg : Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: root.isPlaying ? Config.actFg : Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: Config.iconSize
            }
        }

        // Title and Artist
        ColumnLayout {
            spacing: 0
            Layout.maximumWidth: 150
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: root.title
                color: Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: 150
            }

            Text {
                visible: root.artist !== ""
                text: root.artist
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 1
                elide: Text.ElideRight
                Layout.maximumWidth: 150
            }
        }

        // Playback Controls
        RowLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            // Previous
            IslandButton {
                icon: "󰒮"
                tooltip: "Previous Track"
                customPaddingH: 4
                customPaddingV: 2
                onClicked: {
                    if (root.activePlayer) root.activePlayer.previous();
                }
            }

            // Play / Pause
            IslandButton {
                icon: root.isPlaying ? "󰏤" : "󰐊"
                tooltip: root.isPlaying ? "Pause" : "Play"
                customPaddingH: 4
                customPaddingV: 2
                active: root.isPlaying
                onClicked: {
                    if (root.activePlayer) root.activePlayer.playPause();
                }
            }

            // Next
            IslandButton {
                icon: "󰒭"
                tooltip: "Next Track"
                customPaddingH: 4
                customPaddingV: 2
                onClicked: {
                    if (root.activePlayer) root.activePlayer.next();
                }
            }
        }
    }
}
