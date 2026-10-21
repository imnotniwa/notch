import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

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
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "No Media Playing") : "No Media Playing"
    readonly property string artist: {
        if (!activePlayer || !activePlayer.trackArtists) return "Music";
        if (Array.isArray(activePlayer.trackArtists)) return activePlayer.trackArtists.join(", ");
        return activePlayer.trackArtists.toString() || "Music";
    }
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // Large Album Art with rounded corners & source badge (Reference 1)
        Rectangle {
            id: artBox
            implicitWidth: 84
            implicitHeight: 84
            radius: 14
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

            // Fallback vinyl icon if no album art loaded
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.1, 0.1, 0.15, 0.8)
                visible: root.artUrl === "" || artBox.children[0].status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: root.isPlaying ? Config.actFg : Config.dimFg
                    font.family: Config.fontFamily
                    font.pixelSize: 32
                }
            }

            // Floating app identity badge (e.g. music note in bottom right corner)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 4
                width: 18
                height: 18
                radius: 5
                color: root.isPlaying ? Config.actBg : Config.subPillBg
                border.color: Config.subPillBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: "#ffffff"
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        // Center: Track Title, Artist, and Transport Controls (Reference 1)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Track Title
            Item {
                id: titleContainer
                Layout.fillWidth: true
                implicitHeight: titleTxt.implicitHeight
                clip: true

                readonly property bool needsScroll: titleTxt.paintedWidth > width
                readonly property real scrollDistance: Math.max(0, titleTxt.paintedWidth - width + 24)

                Text {
                    id: titleTxt
                    x: 0
                    text: root.title
                    color: Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: titleContainer.needsScroll ? Text.ElideNone : Text.ElideRight

                    onTextChanged: {
                        x = 0;
                        if (titleContainer.needsScroll && marqueeSeq.running) marqueeSeq.restart();
                    }
                }

                SequentialAnimation {
                    id: marqueeSeq
                    running: titleContainer.needsScroll && Config.notchVisible
                    loops: Animation.Infinite

                    PauseAnimation { duration: 1800 }
                    NumberAnimation {
                        target: titleTxt
                        property: "x"
                        from: 0
                        to: -titleContainer.scrollDistance
                        duration: Math.max(1200, titleContainer.scrollDistance * 32)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 1600 }
                    NumberAnimation {
                        target: titleTxt
                        property: "x"
                        from: -titleContainer.scrollDistance
                        to: 0
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Artist Name
            Text {
                text: root.artist
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Transport Controls (Reference 1: <<  ||  >>)
            RowLayout {
                spacing: 12
                Layout.topMargin: 4

                // Prev
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: prevM.pressed ? Qt.rgba(1, 1, 1, 0.2) : (prevM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                    scale: prevM.pressed ? 0.90 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: prevM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activePlayer) root.activePlayer.previous();
                        }
                    }

                    StyledTooltip {
                        text: "Previous Track"
                        visible: prevM.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Config.activeAnchorEdge === "bottom" ? (-implicitHeight - 8) : (parent.height + 8)
                    }
                }

                // Play / Pause
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: root.isPlaying ? Config.actBg : Qt.rgba(1, 1, 1, 0.14)
                    border.color: root.isPlaying ? "transparent" : Config.subPillBorder
                    border.width: 1
                    scale: playM.pressed ? 0.92 : 1.0

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        color: Config.actFg
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: playM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.activePlayer) return;
                            if (typeof root.activePlayer.togglePlaying === "function") {
                                root.activePlayer.togglePlaying();
                            } else if (root.isPlaying) {
                                root.activePlayer.pause();
                            } else {
                                root.activePlayer.play();
                            }
                        }
                    }

                    StyledTooltip {
                        text: root.isPlaying ? "Pause" : "Play"
                        visible: playM.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Config.activeAnchorEdge === "bottom" ? (-implicitHeight - 8) : (parent.height + 8)
                    }
                }

                // Next
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: nextM.pressed ? Qt.rgba(1, 1, 1, 0.2) : (nextM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                    scale: nextM.pressed ? 0.90 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: nextM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activePlayer) root.activePlayer.next();
                        }
                    }

                    StyledTooltip {
                        text: "Next Track"
                        visible: nextM.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Config.activeAnchorEdge === "bottom" ? (-implicitHeight - 8) : (parent.height + 8)
                    }
                }
            }
        }

        // Right side: Audio Equalizer Waveform bars (Reference 1)
        RowLayout {
            spacing: 3
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: 8

            Repeater {
                model: 4

                Rectangle {
                    id: waveBar
                    required property int index
                    width: 3
                    radius: 2
                    color: root.isPlaying ? Config.actBg : Config.dimFg

                    height: 8

                    SequentialAnimation on height {
                        running: root.isPlaying
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 10 + (waveBar.index * 4)
                            duration: 220 + (waveBar.index * 60)
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 6 + ((3 - waveBar.index) * 3)
                            duration: 240 + (waveBar.index * 50)
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
