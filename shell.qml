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

                // Click-through mask:
                // When notch is hidden, only the top trigger hotspot is masked.
                // When notch is visible, the entire island receives pointer input.
                mask: Region {
                    item: Config.notchVisible ? island : topTrigger
                }

                // Top Edge Hotspot: catches mouse hovering strictly within notch's width at top bezel
                Item {
                    id: topTrigger
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: island.implicitWidth
                    height: 8

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                Config.notchHovered = true;
                            }
                        }
                    }
                }

                Island {
                    id: island
                    anchors.horizontalCenter: parent.horizontalCenter
                }
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
