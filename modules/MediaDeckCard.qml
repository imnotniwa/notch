import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    // Track user-selected player index, defaulting to the first playing player
    property int selectedPlayerIdx: 0

    readonly property var playerList: {
        if (!Mpris.players || !Mpris.players.values) return [];
        return Mpris.players.values;
    }

    readonly property var activePlayer: {
        if (root.playerList.length === 0) return null;
        if (root.selectedPlayerIdx >= 0 && root.selectedPlayerIdx < root.playerList.length) {
            return root.playerList[root.selectedPlayerIdx];
        }
        for (let i = 0; i < root.playerList.length; i++) {
            if (root.playerList[i].playbackState === MprisPlaybackState.Playing) return root.playerList[i];
        }
        return root.playerList[0];
    }

    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "No Media Playing") : "No Media Playing"
    readonly property string artist: {
        if (!activePlayer || !activePlayer.trackArtists) return "Audio";
        if (Array.isArray(activePlayer.trackArtists)) return activePlayer.trackArtists.join(", ");
        return activePlayer.trackArtists.toString() || "Audio";
    }
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    // Normalize track length (converts microseconds to seconds if > 100000)
    readonly property real trackLengthSecs: {
        if (!activePlayer) return 0;
        let l = activePlayer.length || 0;
        return l > 100000 ? (l / 1000000.0) : l;
    }

    // High-precision interpolated position tracker
    property real basePosSecs: 0
    property real lastSyncEpoch: Date.now()
    property real displayPositionSecs: 0

    function syncPositionFromPlayer() {
        if (!activePlayer) {
            basePosSecs = 0;
            displayPositionSecs = 0;
            return;
        }
        let raw = activePlayer.position || 0;
        let p = raw > 100000 ? (raw / 1000000.0) : raw;
        basePosSecs = p;
        lastSyncEpoch = Date.now();
        displayPositionSecs = p;
    }

    // Sync whenever activePlayer or track changes
    onActivePlayerChanged: syncPositionFromPlayer()
    onTitleChanged: syncPositionFromPlayer()

    Connections {
        target: root.activePlayer
        function onPositionChanged() {
            root.syncPositionFromPlayer();
        }
        function onPlaybackStateChanged() {
            root.syncPositionFromPlayer();
        }
    }

    // Smooth real-time position clock (interpolates every 250ms when playing)
    Timer {
        id: positionClock
        interval: 250
        repeat: true
        running: root.isPlaying && Config.notchVisible
        onTriggered: {
            if (root.isPlaying) {
                let elapsed = (Date.now() - root.lastSyncEpoch) / 1000.0;
                let cur = root.basePosSecs + elapsed;
                if (root.trackLengthSecs > 0) {
                    cur = Math.min(cur, root.trackLengthSecs);
                }
                root.displayPositionSecs = cur;
            }
        }
    }

    // Periodic sync heartbeat to correct any drift
    Timer {
        interval: 3000
        repeat: true
        running: Config.notchVisible && root.isPlaying
        onTriggered: {
            // Re-sync with actual MPRIS source to eliminate clock drift
            if (root.activePlayer) {
                let raw = root.activePlayer.position || 0;
                let p = raw > 100000 ? (raw / 1000000.0) : raw;
                if (Math.abs(p - root.displayPositionSecs) > 1.2) {
                    root.syncPositionFromPlayer();
                }
            }
        }
    }

    readonly property real progressFrac: trackLengthSecs > 0 ? Math.min(1.0, Math.max(0.0, displayPositionSecs / trackLengthSecs)) : 0.0

    // Format seconds to mm:ss or hh:mm:ss
    function formatTime(s) {
        if (isNaN(s) || s < 0) return "0:00";
        let total = Math.floor(s);
        let hrs = Math.floor(total / 3600);
        let mins = Math.floor((total % 3600) / 60);
        let secs = total % 60;
        let padSecs = (secs < 10 ? "0" : "") + secs;

        if (hrs > 0) {
            let padMins = (mins < 10 ? "0" : "") + mins;
            return hrs + ":" + padMins + ":" + padSecs;
        }
        return mins + ":" + padSecs;
    }

    // Seek helper using playerctl for rock-solid browser / system seek
    function seekToSeconds(targetSecs) {
        if (!activePlayer) return;
        let clamped = Math.max(0, root.trackLengthSecs > 0 ? Math.min(targetSecs, root.trackLengthSecs) : targetSecs);
        root.basePosSecs = clamped;
        root.displayPositionSecs = clamped;
        root.lastSyncEpoch = Date.now();

        // Native MPRIS seek if supported, backed by playerctl for browser compatibility
        let identity = (activePlayer.identity || "").toLowerCase();
        let nameParam = identity.includes("brave") ? "brave" : (identity.includes("firefox") ? "firefox" : (identity.includes("chromium") ? "chromium" : (identity.includes("chrome") ? "chrome" : "")));
        if (nameParam !== "") {
            Config.run("playerctl -p " + nameParam + " position " + Math.round(clamped));
        } else {
            Config.run("playerctl position " + Math.round(clamped));
        }
    }

    function seekOffset(offsetSecs) {
        if (!activePlayer) return;
        let target = root.displayPositionSecs + offsetSecs;
        seekToSeconds(target);
    }

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // =====================================================================
        // LEFT HALF: Full Active Media Player
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Top Row: Album Artwork + Title/Artist
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Album Art thumbnail with adaptive squircle
                Rectangle {
                    implicitWidth: 72
                    implicitHeight: 72
                    radius: 16
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

                    // Fallback artwork
                    Rectangle {
                        anchors.fill: parent
                        visible: root.artUrl === "" || (root.artUrl !== "" && parent.children[0].status !== Image.Ready)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#2c3e50" }
                            GradientStop { position: 1.0; color: "#000000" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: root.isPlaying ? Config.actBg : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 26
                        }
                    }
                }

                // Title & Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: root.title
                        color: Config.mainFg
                        font.family: Config.bodyFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.artist
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Active playing indicator
                    RowLayout {
                        spacing: 4
                        visible: root.isPlaying

                        Text {
                            text: "󰎆 Playing"
                            color: Config.actBg
                            font.family: Config.bodyFont
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // Scrubber Progress Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Interactive Progress Track
                Rectangle {
                    id: scrubTrack
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, Math.min(parent.width, parent.width * root.progressFrac))
                        radius: parent.radius
                        color: Config.actBg
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (root.activePlayer && root.trackLengthSecs > 0) {
                                let ratio = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                root.seekToSeconds(ratio * root.trackLengthSecs);
                            }
                        }
                    }
                }

                // Elapsed & Remaining Timestamps
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.displayPositionSecs)
                        color: Config.dimFg
                        font.family: Config.monoFont
                        font.pixelSize: 10
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.trackLengthSecs > 0 ? root.formatTime(root.trackLengthSecs) : "--:--"
                        color: Config.dimFg
                        font.family: Config.monoFont
                        font.pixelSize: 10
                    }
                }
            }

            // Transport Controls: [ 10s Rewind ] [ Prev ] [ Play/Pause ] [ Next ] [ 10s Forward ]
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                // Rewind 10s
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: r10M.pressed ? Qt.rgba(1, 1, 1, 0.20) : (r10M.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰑋"
                        color: Config.mainFg
                        font.family: Config.iconFont
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: r10M
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.seekOffset(-10);
                        }
                    }
                }

                // Previous
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: prevM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (prevM.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Config.mainFg
                        font.family: Config.iconFont
                        font.pixelSize: 15
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

                // Play / Pause (Large Primary Button)
                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 42
                    radius: 21
                    color: playM.pressed ? Qt.darker(Config.actBg, 1.2) : (playM.containsMouse ? Qt.lighter(Config.actBg, 1.1) : (root.isPlaying ? Config.actBg : Qt.rgba(1, 1, 1, 0.15)))
                    border.color: root.isPlaying ? "transparent" : Qt.rgba(1, 1, 1, 0.20)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        color: "#ffffff"
                        font.family: Config.iconFont
                        font.pixelSize: 18
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
                }

                // Next
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: nextM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (nextM.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Config.mainFg
                        font.family: Config.iconFont
                        font.pixelSize: 15
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

                // Forward 10s
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: f10M.pressed ? Qt.rgba(1, 1, 1, 0.20) : (f10M.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰑋"
                        scale: -1
                        color: Config.mainFg
                        font.family: Config.iconFont
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: f10M
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.seekOffset(10);
                        }
                    }
                }
            }
        }

        // Vertical divider
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // =====================================================================
        // RIGHT HALF: Multi-Source Switcher (All Active Players / Tabs)
        // =====================================================================
        ColumnLayout {
            Layout.preferredWidth: 230
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "MEDIA SOURCES"
                    color: Config.dimFg
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.playerList.length + " active"
                    color: Config.dimFg
                    font.family: Config.monoFont
                    font.pixelSize: 10
                }
            }

            // Player List
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.playerList

                delegate: Rectangle {
                    id: pRow
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    implicitHeight: 46
                    radius: 10

                    readonly property bool isSelected: root.activePlayer === pRow.modelData
                    readonly property bool isThisPlaying: pRow.modelData.playbackState === MprisPlaybackState.Playing

                    color: isSelected ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.18) : (pMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.03))
                    border.color: isSelected ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.45) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // Status Dot / Play Icon
                        Text {
                            text: pRow.isThisPlaying ? "󰐊" : "󰏤"
                            color: pRow.isThisPlaying ? Config.actBg : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Title & Player Name
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                text: pRow.modelData.trackTitle || "Media Stream"
                                color: pRow.isSelected ? "#ffffff" : Config.mainFg
                                font.family: Config.bodyFont
                                font.pixelSize: 12
                                font.weight: pRow.isSelected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    let art = pRow.modelData.trackArtists;
                                    let str = Array.isArray(art) ? art.join(", ") : (art || "");
                                    return str !== "" ? str : (pRow.modelData.identity || "Browser");
                                }
                                color: Config.dimFg
                                font.family: Config.bodyFont
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: pMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedPlayerIdx = pRow.index;
                        }
                    }
                }

                // Empty state if no media sources detected
                Text {
                    anchors.centerIn: parent
                    text: "No active media"
                    color: Config.dimFg
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    visible: root.playerList.length === 0
                }
            }
        }
    }
}
