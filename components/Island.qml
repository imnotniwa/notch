import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    // Symmetrical Pill Capsule sizing with Apple proportions
    implicitWidth: Math.max(expandedRow.implicitWidth + 32, 780)
    implicitHeight: Config.expandedHeight

    // Hanging Apple Notch geometry: anchored seamlessly to the top bezel, bottom corners rounded
    bottomLeftRadius: 22
    bottomRightRadius: 22
    topLeftRadius: 0
    topRightRadius: 0

    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1

    // Fluid organic expansion anchored to top bezel
    transformOrigin: Item.Top
    scale: Config.notchVisible ? 1.0 : 0.70
    opacity: Config.notchVisible ? 1.0 : 0.0

    // Vertical slide: -1 to anchor directly flush into the top screen bezel
    y: Config.notchVisible ? -1 : -(implicitHeight + 10)

    // Flush top seam cover to ensure zero gap or light leak with the top bezel
    Rectangle {
        anchors.top: parent.top
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
