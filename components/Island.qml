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

    // Vertical slide transition: 0 when visible hanging from top, tucked offscreen when hidden
    y: Config.notchVisible ? 0 : -implicitHeight

    Behavior on y {
        NumberAnimation {
            duration: Config.notchVisible ? 240 : 200
            easing.type: Config.notchVisible ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.08
        }
    }

    // Deck View: Media & System Controls Deck
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        spacing: 8

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

    // Graceful hover hysteresis timer to prevent flicker near edges
    Timer {
        id: exitHysteresisTimer
        interval: 220
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
