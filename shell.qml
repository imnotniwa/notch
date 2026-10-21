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

                // Detect whether this screen should anchor top or bottom
                readonly property string anchorEdge: Config.getAnchorForScreen(modelData, Quickshell.screens)
                readonly property bool isBottomAnchor: anchorEdge === "bottom"

                Component.onCompleted: {
                    if (visible) Config.activeAnchorEdge = anchorEdge;
                }

                onVisibleChanged: {
                    if (visible) {
                        Config.activeAnchorEdge = anchorEdge;
                    }
                }

                anchors {
                    top: !barWindow.isBottomAnchor
                    bottom: barWindow.isBottomAnchor
                    left: true
                    right: true
                }

                // Window height provides space for hanging/docked island and tooltips
                implicitHeight: Config.expandedHeight + 46
                color: "transparent"

                // Zero exclusiveZone: Never resize, tile, or disturb application windows!
                exclusiveZone: 0

                // Symmetrical Dynamic Island Anchor:
                // Perfectly centered horizontally on the display
                property real targetX: Math.round((barWindow.width - island.implicitWidth) / 2)

                // Click-through mask:
                // When notch is hidden, only the edge trigger hotspot is masked.
                // When notch is visible, the entire island and its active interaction zone receive pointer input.
                mask: Region {
                    item: Config.notchVisible ? barWindowArea : edgeTrigger
                }

                // Interactive region when visible: encompasses island + tooltip space
                Item {
                    id: barWindowArea
                    x: island.x
                    y: barWindow.isBottomAnchor ? island.y - 40 : island.y
                    width: island.width
                    height: island.height + 40
                }

                // Bezel Edge Hotspot: catches mouse hovering along the anchor bezel centered with the island
                Item {
                    id: edgeTrigger
                    anchors.top: barWindow.isBottomAnchor ? undefined : parent.top
                    anchors.bottom: barWindow.isBottomAnchor ? parent.bottom : undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: island.implicitWidth
                    height: 8

                    HoverHandler {
                        id: edgeHover
                        onHoveredChanged: {
                            if (hovered) {
                                Config.notchHovered = true;
                            }
                        }
                    }
                }

                Island {
                    id: island
                    x: barWindow.targetX
                    anchorEdge: barWindow.anchorEdge

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

    // Apple-style Taskbar App Context Menu Window per screen
    Variants {
        model: Config.appMenuVisible ? Quickshell.screens : []
        delegate: Component {
            AppContextMenu {
                required property var modelData
                screen: modelData
                visible: modelData.name === activeMonitorName && Config.appMenuVisible
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
