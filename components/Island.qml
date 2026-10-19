import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    // Sizing animates smoothly between compact and expanded
    property bool isExpanded: Config.expanded

    implicitWidth: isExpanded ? Math.max(expandedRow.implicitWidth + 36, 760) : (compactView.implicitWidth + 32)
    implicitHeight: isExpanded ? Config.expandedHeight : Config.compactHeight

    // Smooth hanging notch corners: bottom corners rounded, top flush with screen edge
    bottomLeftRadius: isExpanded ? 22 : Config.pillRadius
    bottomRightRadius: isExpanded ? 22 : Config.pillRadius
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

    // Apple fluid spring morphing (WWDC 2018: Designing Fluid Interfaces)
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.springDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // Compact View (visible when resting with coordinated scale & cross-fade)
    CompactIsland {
        id: compactView
        anchors.centerIn: parent
        visible: opacity > 0.02
        opacity: root.isExpanded ? 0 : 1
        scale: root.isExpanded ? 0.92 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // Expanded View (Recommendation A: Media & Quick Settings Deck)
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        visible: opacity > 0.02
        opacity: root.isExpanded ? 1 : 0
        scale: root.isExpanded ? 1.0 : 0.94
        spacing: 8

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.06 }
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

    TapHandler {
        enabled: !root.isExpanded
        onTapped: {
            Config.manualExpand = !Config.manualExpand;
        }
    }
}
