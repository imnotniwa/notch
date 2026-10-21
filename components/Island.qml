import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    property string anchorEdge: "top"
    readonly property bool isBottomAnchor: anchorEdge === "bottom"
    readonly property bool isExpanded: Config.expanded

    // Symmetrical Dynamic Island geometry: morphs smoothly between compact and full deck
    implicitWidth: isExpanded ? Math.max(expandedRow.implicitWidth + 36, 960) : Math.max(compactRow.implicitWidth + 32, 420)
    implicitHeight: isExpanded ? Config.expandedHeight : 38

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

    // =========================================================================
    // TIER 2: COMPACT GLANCE BAR (Hover view: clean, centered, glanceable metrics)
    // =========================================================================
    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: 10
        visible: !root.isExpanded
        opacity: !root.isExpanded ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        // Left Glance: SysMon compact stats
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            SysMonModule {
                compactMode: true
            }
        }

        // Center Glance: Clock & Media
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            ClockModule {}

            MediaModule {
                id: compactMedia
                compactMode: true
            }

            TaskbarModule {
                visible: !compactMedia.hasMedia
            }
        }

        // Right Glance: Volume & Battery
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            AudioModule {
                compactMode: true
            }

            BatteryModule {
                compactMode: true
            }
        }
    }

    // =========================================================================
    // TIER 3: FULL DECK (Grouped 4-Card Rich Modular Layout)
    // =========================================================================
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        spacing: 8
        visible: root.isExpanded
        opacity: root.isExpanded ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // ----------------------------------------------------
        // GROUP A: System & Workspaces (Left Wing)
        // ----------------------------------------------------
        IslandPill {
            spacing: 6
            WorkspacesModule {}
            SysMonModule {
                compactMode: false
            }
        }

        // ----------------------------------------------------
        // GROUP B: Center Core (Clock + Live Media + Taskbar)
        // ----------------------------------------------------
        IslandPill {
            paddingHorizontal: 10
            spacing: 8

            ClockModule {}

            MediaModule {
                id: expandedMedia
                compactMode: false
            }

            TaskbarModule {
                visible: !expandedMedia.hasMedia
            }
        }

        // ----------------------------------------------------
        // GROUP C: Connectivity & Hardware Levels (Right Wing)
        // ----------------------------------------------------
        IslandPill {
            spacing: 6
            NetworkModule {}
            AudioModule {
                compactMode: false
            }
            BacklightModule {}
            BatteryModule {
                compactMode: false
            }
        }

        // ----------------------------------------------------
        // GROUP D: Control Center, Utilities, Tray & Power
        // ----------------------------------------------------
        IslandPill {
            spacing: 4

            // Utilities & Quick Actions
            CaffeineModule {}
            UpdatesModule {}
            ActionsModule {}

            // System Tray
            TrayModule {
                id: trayMod
                visible: trayMod.implicitWidth > 0
            }

            // Quick Settings (Sunset, Lock, Power)
            QuickSettingsModule {}

            // Deck Pin Toggle
            IslandButton {
                icon: Config.isPinned ? "󰐃" : "󰤱"
                tooltip: Config.isPinned ? "Unpin Dynamic Island" : "Pin Dynamic Island open"
                active: Config.isPinned
                onClicked: {
                    Config.isPinned = !Config.isPinned;
                    if (!Config.isPinned) {
                        Config.isDeckOpen = false;
                    }
                }
            }
        }
    }

    // Click anywhere on Island to toggle Full Deck
    MouseArea {
        anchors.fill: parent
        z: -1 // Behind child buttons so child buttons get priority click events
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
