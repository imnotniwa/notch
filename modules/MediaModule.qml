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

    implicitWidth: hasMedia ? contentRow.implicitWidth + 8 : 0
    implicitHeight: 30
    visible: hasMedia

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // Music icon or album art: Apple circular badge
        Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: root.isPlaying ? Config.actBg : Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: root.isPlaying ? Config.actFg : Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: Config.iconSize
            }
        }

        // Title and Artist with Apple-style smooth marquee scrolling on overflow
        ColumnLayout {
            id: textCol
            spacing: 0
            Layout.preferredWidth: 140
            Layout.maximumWidth: 140
            Layout.alignment: Qt.AlignVCenter

            // Marquee Track Title
            Item {
                id: titleContainer
                width: 140
                height: titleText.implicitHeight
                clip: true

                readonly property bool needsScroll: titleText.paintedWidth > width
                readonly property real scrollDistance: Math.max(0, titleText.paintedWidth - width + 18)

                Text {
                    id: titleText
                    x: 0
                    text: root.title
                    color: Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.weight: Font.DemiBold

                    onTextChanged: {
                        x = 0;
                        if (titleContainer.needsScroll && marqueeAnim.running) {
                            marqueeAnim.restart();
                        }
                    }
                }

                SequentialAnimation {
                    id: marqueeAnim
                    running: titleContainer.needsScroll && Config.notchVisible
                    loops: Animation.Infinite

                    PauseAnimation { duration: 1800 }

                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: -titleContainer.scrollDistance
                        duration: Math.max(1200, titleContainer.scrollDistance * 30)
                        easing.type: Easing.Linear
                    }

                    PauseAnimation { duration: 1800 }

                    NumberAnimation {
                        target: titleText
                        property: "x"
                        to: 0
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Artist line
            Item {
                id: artistContainer
                visible: root.artist !== ""
                width: 140
                height: artistText.implicitHeight
                clip: true

                readonly property bool needsScroll: artistText.paintedWidth > width
                readonly property real scrollDistance: Math.max(0, artistText.paintedWidth - width + 18)

                Text {
                    id: artistText
                    x: 0
                    text: root.artist
                    color: Config.dimFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize - 1

                    onTextChanged: {
                        x = 0;
                        if (artistContainer.needsScroll && artistMarqueeAnim.running) {
                            artistMarqueeAnim.restart();
                        }
                    }
                }

                SequentialAnimation {
                    id: artistMarqueeAnim
                    running: artistContainer.needsScroll && Config.notchVisible
                    loops: Animation.Infinite

                    PauseAnimation { duration: 2200 }

                    NumberAnimation {
                        target: artistText
                        property: "x"
                        to: -artistContainer.scrollDistance
                        duration: Math.max(1200, artistContainer.scrollDistance * 32)
                        easing.type: Easing.Linear
                    }

                    PauseAnimation { duration: 1800 }

                    NumberAnimation {
                        target: artistText
                        property: "x"
                        to: 0
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // Playback Controls - Apple Dynamic Island Transport Controls
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            // Previous
            Rectangle {
                id: prevBtn
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: prevArea.pressed ? Qt.rgba(1, 1, 1, 0.18) : (prevArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")
                scale: prevArea.pressed ? 0.90 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: prevArea.pressed ? 60 : 180
                        easing.type: prevArea.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: prevArea.containsMouse ? Config.hvrFg : Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.iconSize
                }

                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer) root.activePlayer.previous();
                    }
                }
            }

            // Play / Pause - Apple Primary Pill / Circle Accent
            Rectangle {
                id: playBtn
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: root.isPlaying ? (playArea.pressed ? Qt.darker(Config.actBg, 1.2) : Config.actBg) : (playArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : (playArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)))
                border.color: root.isPlaying ? "transparent" : Config.subPillBorder
                border.width: 1
                scale: playArea.pressed ? 0.90 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: playArea.pressed ? 60 : 180
                        easing.type: playArea.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    // Slight optical visual centering compensation for play triangle vs pause bars
                    anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    color: root.isPlaying ? Config.actFg : Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.iconSize + 1
                }

                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.activePlayer) return;
                        if (typeof root.activePlayer.togglePlaying === "function") {
                            root.activePlayer.togglePlaying();
                        } else if (root.isPlaying && typeof root.activePlayer.pause === "function") {
                            root.activePlayer.pause();
                        } else if (typeof root.activePlayer.play === "function") {
                            root.activePlayer.play();
                        }
                    }
                }
            }

            // Next
            Rectangle {
                id: nextBtn
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: nextArea.pressed ? Qt.rgba(1, 1, 1, 0.18) : (nextArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")
                scale: nextArea.pressed ? 0.90 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: nextArea.pressed ? 60 : 180
                        easing.type: nextArea.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: nextArea.containsMouse ? Config.hvrFg : Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.iconSize
                }

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer) root.activePlayer.next();
                    }
                }
            }
        }
    }
}
