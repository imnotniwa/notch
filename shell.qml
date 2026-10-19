import QtQuick
import Quickshell
import "components"
import "."

ShellRoot {
    // Single Top Bar Window on Primary Screen
    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

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
                // When notch is hidden, only the 3px top trigger hotspot is masked.
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
                    height: 4

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
                    anchors.top: parent.top
                    anchors.topMargin: 0
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
