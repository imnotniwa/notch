import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    property string anchorEdge: "top"
    readonly property bool isBottomAnchor: anchorEdge === "bottom"
    readonly property bool isExpanded: Config.expanded

    // Symmetrical Dynamic Island geometry: morphs smoothly between compact pill, compact media pill, and full deck gallery
    // Media stays active when playing OR when paused while the notch remains in focus/hovered
    readonly property bool mediaActiveOrHoverPaused: compactMedia.hasMedia && (compactMedia.isPlaying || (Config.notchVisible && compactMedia.title !== ""))
    readonly property bool hasActiveMedia: mediaActiveOrHoverPaused
    readonly property int standardCompactWidth: Math.max(compactRow.implicitWidth + 32, 280)
    readonly property int compactMediaWidth: Math.max(compactMediaPill.implicitWidth + 32, 490)

    implicitWidth: isExpanded ? Config.deckWidth : (hasActiveMedia ? compactMediaWidth : standardCompactWidth)
    implicitHeight: isExpanded ? Config.expandedHeight : Config.compactHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 1.05
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutQuad
        }
    }

    // Corner radius adapted to orientation and expansion state
    bottomLeftRadius: root.isBottomAnchor ? 0 : (isExpanded ? 22 : 18)
    bottomRightRadius: root.isBottomAnchor ? 0 : (isExpanded ? 22 : 18)
    topLeftRadius: root.isBottomAnchor ? (isExpanded ? 22 : 18) : 0
    topRightRadius: root.isBottomAnchor ? (isExpanded ? 22 : 18) : 0

    Behavior on bottomLeftRadius { NumberAnimation { duration: 180 } }
    Behavior on bottomRightRadius { NumberAnimation { duration: 180 } }
    Behavior on topLeftRadius { NumberAnimation { duration: 180 } }
    Behavior on topRightRadius { NumberAnimation { duration: 180 } }

    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1

    // Fluid organic expansion anchored to the respective screen bezel
    transformOrigin: root.isBottomAnchor ? Item.Bottom : Item.Top
    scale: Config.notchVisible ? 1.0 : 0.70
    opacity: Config.notchVisible ? 1.0 : 0.0

    // Vertical slide:
    y: {
        if (root.isBottomAnchor) {
            return Config.notchVisible ? (parent.height - implicitHeight + 1) : (parent.height + 10);
        } else {
            return Config.notchVisible ? -1 : -(implicitHeight + 10);
        }
    }

    // Flush bezel seam cover: eliminates any sub-pixel gap or light leak with the active bezel
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        y: root.isBottomAnchor ? (parent.height - 2) : 0
        height: 2
        color: Config.islandBg
        z: 2
    }

    Behavior on y {
        NumberAnimation {
            duration: Config.notchVisible ? 260 : 190
            easing.type: Config.notchVisible ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.10
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Config.notchVisible ? 260 : 180
            easing.type: Config.notchVisible ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.08
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.notchVisible ? 180 : 140
            easing.type: Easing.OutCubic
        }
    }

    // Hidden media detector to track playback state
    MediaModule {
        id: compactMedia
        visible: false
        compactMode: true
    }

    // =========================================================================
    // TIER 1: STREAMLINED COMPACT GLANCE BAR (Time & Date, Volume, Battery Charging Mode)
    // =========================================================================
    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: 12
        visible: !root.isExpanded && !root.hasActiveMedia
        opacity: (!root.isExpanded && !root.hasActiveMedia) ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        // Time and Date
        ClockModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Volume
        AudioModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Battery with clear charging status
        BatteryModule {
            compactMode: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // =========================================================================
    // DYNAMIC APPLE COMPACT MEDIA PILL (Active when media is playing or paused-in-focus)
    // =========================================================================
    CompactMediaPill {
        id: compactMediaPill
        anchors.centerIn: parent
        visible: !root.isExpanded && root.hasActiveMedia
        opacity: (!root.isExpanded && root.hasActiveMedia) ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    // =========================================================================
    // TIER 2: FULL DECK GALLERY (Large Apple card with category tabs)
    // =========================================================================
    IslandGallery {
        id: expandedGallery
        anchors.fill: parent
        anchors.margins: 12
        visible: root.isExpanded
        opacity: root.isExpanded ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // Auto-focus on Media tab if audio is playing when opening deck
    onIsExpandedChanged: {
        if (isExpanded) {
            if (compactMedia.hasMedia && compactMedia.isPlaying) {
                Config.galleryIndex = 0; // Media card focus (Reference 1)
            }
        }
    }

    // Click anywhere on Island to toggle Full Deck
    MouseArea {
        anchors.fill: parent
        // In compact mode, capture clicks across the whole bar so child items don't intercept it.
        // In rich media / expanded deck, put z: -1 so child buttons (media transport, tabs, etc.) receive clicks.
        z: (!root.isExpanded && !root.hasActiveMedia) ? 10 : -1
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Config.isDeckOpen = !Config.isDeckOpen;
        }
    }

    // Graceful hover hysteresis timer to tuck away when cursor leaves notch area
    Timer {
        id: exitHysteresisTimer
        interval: 350
        onTriggered: {
            if (!Config.isPinned && !Config.powerModalVisible && !Config.trayMenuVisible && !Config.appMenuVisible) {
                Config.isHovered = false;
                Config.notchHovered = false;
                Config.isDeckOpen = false;
            }
        }
    }

    // Modern pointer handlers: Never block child button clicks
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                exitHysteresisTimer.stop();
                Config.notchHovered = true;
                Config.isHovered = true;
            } else {
                exitHysteresisTimer.restart();
            }
        }
    }
}
