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

    radius: isExpanded ? 20 : Config.pillRadius
    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1

    // Elastic Apple Dynamic Island morph animation
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.springDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on radius {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // Compact View (visible when resting)
    CompactIsland {
        id: compactView
        anchors.centerIn: parent
        visible: opacity > 0.05
        opacity: root.isExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    // Expanded View (Recommendation A: Media & Quick Settings Deck)
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        visible: opacity > 0.05
        opacity: root.isExpanded ? 1 : 0
        spacing: 8

        Behavior on opacity {
            NumberAnimation { duration: 220 }
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

    // Modern pointer handlers: Never block child button clicks
    HoverHandler {
        onHoveredChanged: {
            Config.isHovered = hovered;
        }
    }

    TapHandler {
        enabled: !root.isExpanded
        onTapped: {
            Config.manualExpand = !Config.manualExpand;
        }
    }
}
