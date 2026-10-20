//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "components"
import "."

ShellRoot {
    // Dynamic focused monitor tracking: follows active workspace/monitor focus
    readonly property string activeMonitorName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")

    // Top Bar Window per screen: strictly active only on the currently focused monitor
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                // Strictly visible only on the monitor that currently has focus!
                visible: modelData.name === activeMonitorName

                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Window height provides space for hanging island
                implicitHeight: Config.expandedHeight + 14
                color: "transparent"

                // Zero exclusiveZone: Never resize, tile, or disturb application windows!
                exclusiveZone: 0

                // Dynamic Horizontal Anchor: island drops down centered on where cursor entered the top bezel
                property real targetX: (barWindow.width - island.implicitWidth) / 2

                // Click-through mask:
                // When notch is hidden, only the top trigger hotspot is masked.
                // When notch is visible, the entire island receives pointer input.
                mask: Region {
                    item: Config.notchVisible ? island : topTrigger
                }

                // Top Edge Hotspot: catches mouse hovering along the top bezel
                Item {
                    id: topTrigger
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 8

                    HoverHandler {
                        id: topHover
                        onHoveredChanged: {
                            if (hovered) {
                                // Center island on the cursor x touchpoint, clamped within screen margins
                                let halfW = island.implicitWidth / 2;
                                let margin = 16;
                                let minX = margin;
                                let maxX = Math.max(margin, barWindow.width - island.implicitWidth - margin);
                                let desiredX = topHover.point.position.x - halfW;
                                barWindow.targetX = Math.max(minX, Math.min(maxX, desiredX));
                                Config.notchHovered = true;
                            }
                        }
                    }
                }

                Island {
                    id: island
                    x: barWindow.targetX

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // Apple-style Fluid Context Menu Window per screen
    Variants {
        model: Config.trayMenuVisible ? Quickshell.screens : []
        delegate: Component {
            AppleContextMenu {
                required property var modelData
                screen: modelData
                visible: modelData.name === activeMonitorName && Config.trayMenuVisible
            }
        }
    }

    // Centered Modal Window per screen (only created when powerModalVisible is true)
    Variants {
        model: Config.powerModalVisible ? Quickshell.screens : []
        delegate: Component {
            PanelWindow {
                id: modalWindow
                required property var modelData
                screen: modelData
                visible: Config.powerModalVisible

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"

                Loader {
                    anchors.fill: parent
                    active: Config.powerModalVisible
                    asynchronous: false
                    sourceComponent: Component {
                        PowerModal {}
                    }
                }
            }
        }
    }
}
