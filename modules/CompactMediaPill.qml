import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import ".."

Item {
    id: root

    implicitWidth: mainRow.implicitWidth
    implicitHeight: 30

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
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 10

        // Time and Date
        ClockModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Elegant subtle vertical divider
        Rectangle {
            width: 1
            height: 14
            color: Qt.rgba(1, 1, 1, 0.12)
            Layout.alignment: Qt.AlignVCenter
        }

        // Circular Apple album art thumbnail / badge
        Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: root.isPlaying ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.5) : Qt.rgba(1, 1, 1, 0.12)
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

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: root.isPlaying ? Config.actFg : Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: 11
                visible: root.artUrl === "" || parent.children[0].status !== Image.Ready
            }
        }

        // Title with Apple-style smooth marquee scrolling
        Item {
            id: titleContainer
            Layout.preferredWidth: 130
            Layout.maximumWidth: 130
            implicitHeight: titleTxt.implicitHeight
            clip: true
            Layout.alignment: Qt.AlignVCenter

            readonly property bool needsScroll: titleTxt.paintedWidth > width
            readonly property real scrollDistance: Math.max(0, titleTxt.paintedWidth - width + 18)

            Text {
                id: titleTxt
                x: 0
                text: root.title
                color: Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: titleContainer.needsScroll ? Text.ElideNone : Text.ElideRight

                onTextChanged: {
                    x = 0;
                    if (titleContainer.needsScroll && marqueeAnim.running) marqueeAnim.restart();
                }
            }

            SequentialAnimation {
                id: marqueeAnim
                running: titleContainer.needsScroll && Config.notchVisible
                loops: Animation.Infinite

                PauseAnimation { duration: 1800 }
                NumberAnimation {
                    target: titleTxt
                    property: "x"
                    from: 0
                    to: -titleContainer.scrollDistance
                    duration: Math.max(1200, titleContainer.scrollDistance * 30)
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 1600 }
                NumberAnimation {
                    target: titleTxt
                    property: "x"
                    from: -titleContainer.scrollDistance
                    to: 0
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Dynamic 4-Bar Audio Equalizer Waveform
        RowLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 4
                Rectangle {
                    id: waveBar
                    required property int index
                    width: 2.5
                    radius: 1.5
                    color: root.isPlaying ? Config.actBg : Config.dimFg
                    height: root.isPlaying ? 8 : 4

                    SequentialAnimation on height {
                        running: root.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 6 + (waveBar.index * 3)
                            duration: 200 + (waveBar.index * 50)
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 3 + ((3 - waveBar.index) * 2.5)
                            duration: 220 + (waveBar.index * 45)
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        // Media Play/Pause tactile pill
        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: root.isPlaying ? Config.actBg : Qt.rgba(1, 1, 1, 0.12)
            border.color: root.isPlaying ? "transparent" : Qt.rgba(1, 1, 1, 0.14)
            border.width: 1
            scale: playMouse.pressed ? 0.88 : 1.0
            Layout.alignment: Qt.AlignVCenter

            Behavior on scale {
                NumberAnimation { duration: playMouse.pressed ? 60 : 180; easing.type: playMouse.pressed ? Easing.OutQuad : Easing.OutBack; easing.overshoot: 1.15 }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
                text: root.isPlaying ? "󰏤" : "󰐊"
                color: root.isPlaying ? Config.actFg : Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: 11
            }

            MouseArea {
                id: playMouse
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
        }

        // Divider
        Rectangle {
            width: 1
            height: 14
            color: Qt.rgba(1, 1, 1, 0.12)
            Layout.alignment: Qt.AlignVCenter
        }

        // Volume
        AudioModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Battery Charging Status
        BatteryModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
