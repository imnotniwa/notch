import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    // Active MPRIS Media Player tracking
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
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "rockstar") : "rockstar"
    readonly property string artist: {
        if (!activePlayer || !activePlayer.trackArtists) return "Post Malone";
        if (Array.isArray(activePlayer.trackArtists)) {
            let joined = activePlayer.trackArtists.join(", ");
            return joined !== "" ? joined : "Post Malone";
        }
        return activePlayer.trackArtists.toString() || "Post Malone";
    }
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    RowLayout {
        anchors.fill: parent
        spacing: 24

        // =====================================================================
        // LEFT COLUMN: Now Playing Mini Widget + Calendar
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 280
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Mini Now Playing Widget (from Reference)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 12

                // Album Art thumbnail with rounded squircle
                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: root.artUrl !== "" && status === Image.Ready
                    }

                    // Fallback artwork graphic (Apple style lime green gradient with circles like reference)
                    Rectangle {
                        anchors.fill: parent
                        visible: root.artUrl === "" || (root.artUrl !== "" && parent.children[0].status !== Image.Ready)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#b4ec51" }
                            GradientStop { position: 1.0; color: "#429321" }
                        }

                        // Subtle dark decorative circles matching screenshot artwork
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            x: 14
                            y: 18
                            color: Qt.rgba(0, 0, 0, 0.28)
                        }
                    }
                }

                // Title, Artist, and Sound Wave
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: root.title
                            color: Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Mini visualizer waveform icons
                        Text {
                            text: root.isPlaying ? "󰎆" : "󰐊"
                            color: root.isPlaying ? Config.actBg : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        text: root.artist
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Transport Controls: Prev, Play/Pause, Next
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    // Prev
                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: prevM.pressed ? Qt.rgba(1, 1, 1, 0.16) : (prevM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            color: Config.mainFg
                            font.family: Config.iconFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canGoPrevious) {
                                    root.activePlayer.previous();
                                }
                            }
                        }
                    }

                    // Play / Pause (Filled circle button)
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: playM.pressed ? Qt.rgba(1, 1, 1, 0.22) : (playM.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.09))
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "󰏤" : "󰐊"
                            color: Config.mainFg
                            font.family: Config.iconFont
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: playM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canTogglePlaying) {
                                    root.activePlayer.togglePlaying();
                                }
                            }
                        }
                    }

                    // Next
                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        color: nextM.pressed ? Qt.rgba(1, 1, 1, 0.16) : (nextM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            color: Config.mainFg
                            font.family: Config.iconFont
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canGoNext) {
                                    root.activePlayer.next();
                                }
                            }
                        }
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Dynamic Calendar Module
            CalendarModule {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // Vertical column separator
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // =====================================================================
        // RIGHT COLUMN: Quick To-Do Checklist Widget (Full Height)
        // =====================================================================
        TodoModule {
            Layout.preferredWidth: 280
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
