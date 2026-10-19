import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Rectangle {
    id: root

    // Sizing animates smoothly between compact and expanded
    property bool isExpanded: Config.expanded

    implicitWidth: isExpanded ? Math.max(expandedRow.implicitWidth + 32, 700) : (compactView.implicitWidth + 32)
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

    // Expanded View (visible when hovered or pinned)
    RowLayout {
        id: expandedRow
        anchors.centerIn: parent
        visible: opacity > 0.05
        opacity: root.isExpanded ? 1 : 0
        spacing: 8

        Behavior on opacity {
            NumberAnimation { duration: 220 }
        }

        // LEFT PILLS
        // 1. System Monitors (CPU, Memory, GPU)
        IslandPill {
            SysMonModule {}
        }

        // 2. Caffeine & Clock
        IslandPill {
            CaffeineModule {}
            ClockModule {}
        }

        // 3. Workspaces
        IslandPill {
            WorkspacesModule {}
        }

        // CENTER PILL
        // 4. Taskbar / Active Windows
        IslandPill {
            TaskbarModule {}
        }

        // RIGHT PILLS
        // 5. Backlight, Network, Audio, Updates
        IslandPill {
            BacklightModule {}
            NetworkModule {}
            AudioModule {}
            UpdatesModule {}
        }

        // 6. System Tray & Battery
        IslandPill {
            TrayModule {}
            BatteryModule {}
        }

        // 7. Actions & Pin Toggle
        IslandPill {
            ActionsModule {}

            // Pin / Unpin Island Toggle
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

    // Island MouseArea for Hover Detection
    MouseArea {
        id: islandHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Allows child buttons to receive clicks
        propagateComposedEvents: true

        onEntered: {
            Config.isHovered = true;
        }
        onExited: {
            Config.isHovered = false;
        }
    }
}
