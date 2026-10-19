import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    // Sizing animates smoothly between compact and expanded
    implicitWidth: Math.max(expandedRow.implicitWidth + 36, 760)
    implicitHeight: Config.expandedHeight

    // Smooth hanging notch corners: bottom corners rounded, top flush with screen edge
    bottomLeftRadius: 22
    bottomRightRadius: 22
    topLeftRadius: 0
    topRightRadius: 0

    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1

    // Fluid organic water droplet expansion: transforms anchored to top bezel
    transformOrigin: Item.Top
    scale: Config.notchVisible ? 1.0 : 0.60
    opacity: Config.notchVisible ? 1.0 : 0.0

    // Vertical slide transition: -1 when visible (flush/bleeding into top bezel), tucked offscreen when hidden
    y: Config.notchVisible ? -1 : -(implicitHeight + 10)

    // Flush top lip: covers any 1px sub-pixel line or top border seam with bezel
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
            easing.overshoot: 1.14
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Config.notchVisible ? 280 : 180
            easing.type: Config.notchVisible ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.12
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.notchVisible ? 180 : 140
            easing.type: Easing.OutCubic
        }
    }

    // Deck View: Media & System Controls Deck
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        spacing: 8
        opacity: Config.notchVisible ? 1.0 : 0.0
        scale: Config.notchVisible ? 1.0 : 0.88

        Behavior on opacity {
            NumberAnimation {
                duration: Config.notchVisible ? 220 : 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Config.notchVisible ? 240 : 140
                easing.type: Config.notchVisible ? Easing.OutBack : Easing.InQuad
                easing.overshoot: 1.06
            }
        }

        // LEFT CLUSTER: System Monitors, Workspaces & Clock
        IslandPill {
            SysMonModule {}
        }

        IslandPill {
            WorkspacesModule {}
        }

        IslandPill {
            ClockModule {}
        }

        // CENTER CLUSTER: Dynamic Media Player or Taskbar
        IslandPill {
            MediaModule {
                id: mediaModule
            }

            TaskbarModule {
                visible: !mediaModule.hasMedia
            }
        }

        // RIGHT CLUSTER: Hardware Audio, Backlight, Quick Settings & Battery
        IslandPill {
            AudioModule {}
        }

        IslandPill {
            BacklightModule {}
        }

        IslandPill {
            BatteryModule {}
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
