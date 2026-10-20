import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    property string anchorEdge: "top"
    readonly property bool isBottomAnchor: anchorEdge === "bottom"

    // Symmetrical Pill Capsule sizing with Apple proportions
    implicitWidth: Math.max(expandedRow.implicitWidth + 32, 780)
    implicitHeight: Config.expandedHeight

    // Hanging or Docked Apple Notch geometry:
    // When top-anchored: top corners square (0px), bottom corners rounded (22px)
    // When bottom-anchored: bottom corners square (0px), top corners rounded (22px)
    bottomLeftRadius: root.isBottomAnchor ? 0 : 22
    bottomRightRadius: root.isBottomAnchor ? 0 : 22
    topLeftRadius: root.isBottomAnchor ? 22 : 0
    topRightRadius: root.isBottomAnchor ? 22 : 0

    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1

    // Fluid organic expansion anchored to the respective screen bezel
    transformOrigin: root.isBottomAnchor ? Item.Bottom : Item.Top
    scale: Config.notchVisible ? 1.0 : 0.70
    opacity: Config.notchVisible ? 1.0 : 0.0

    // Vertical slide:
    // Top anchor: slides down from offscreen (-implicitHeight - 10) to -1 (flush into top bezel)
    // Bottom anchor: slides up from offscreen (parent.height + 10) to parent.height - implicitHeight + 1 (flush into bottom bezel)
    y: {
        if (root.isBottomAnchor) {
            return Config.notchVisible ? (parent.height - implicitHeight + 1) : (parent.height + 10);
        } else {
            return Config.notchVisible ? -1 : -(implicitHeight + 10);
        }
    }

    // Flush bezel seam cover: eliminates any sub-pixel gap or light leak with the active bezel
    Rectangle {
        anchors.top: root.isBottomAnchor ? undefined : parent.top
        anchors.bottom: root.isBottomAnchor ? parent.bottom : undefined
        anchors.left: parent.left
        anchors.right: parent.right
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

    // Deck View: Balanced Symmetrical Layout
    // Left Wing (SysMon, Workspaces, Battery) <---> Center Core (Clock / Dynamic Island Media) <---> Right Wing (Audio, Backlight, QuickSettings, Pin)
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        spacing: 8
        opacity: Config.notchVisible ? 1.0 : 0.0
        scale: Config.notchVisible ? 1.0 : 0.92

        Behavior on opacity {
            NumberAnimation {
                duration: Config.notchVisible ? 200 : 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Config.notchVisible ? 220 : 140
                easing.type: Config.notchVisible ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.05
            }
        }

        // ====================================================
        // LEFT WING (System & Task Scope): Workspaces, SysMon, Battery
        // ====================================================
        IslandPill {
            WorkspacesModule {}
        }

        IslandPill {
            SysMonModule {}
        }

        IslandPill {
            BatteryModule {}
        }

        // ====================================================
        // CENTER CORE (Anchor & Dynamic Activity): Clock + Dynamic Media
        // ====================================================
        IslandPill {
            paddingHorizontal: 10
            spacing: 8

            // Always present symmetrical focal clock
            ClockModule {}

            // Dynamic Apple Live Activity island module (Media / Active Task)
            MediaModule {
                id: mediaModule
            }

            TaskbarModule {
                visible: !mediaModule.hasMedia
            }
        }

        // ====================================================
        // RIGHT WING (Hardware & Control Center): Audio, Backlight, QuickSettings, Pin
        // ====================================================
        IslandPill {
            AudioModule {}
        }

        IslandPill {
            BacklightModule {}
        }

        IslandPill {
            QuickSettingsModule {}
        }

        IslandPill {
            visible: trayMod.implicitWidth > 0
            TrayModule {
                id: trayMod
            }
        }

        // PIN TOGGLE
        IslandPill {
            paddingHorizontal: 4
            IslandButton {
                icon: Config.isPinned ? "󰐃" : "󰤱"
                tooltip: Config.isPinned ? "Unpin Dynamic Island" : "Pin Dynamic Island open"
                active: Config.isPinned
                onClicked: {
                    Config.isPinned = !Config.isPinned;
                }
            }
        }
    }

    // Graceful hover hysteresis timer to tuck away when cursor leaves notch area
    Timer {
        id: exitHysteresisTimer
        interval: 300
        onTriggered: {
            Config.isHovered = false;
            Config.notchHovered = false;
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
