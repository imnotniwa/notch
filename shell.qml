import QtQuick
import Quickshell
import "components"
import "."

ShellRoot {
    // Top Bar Window per screen: notch shows on whichever screen the cursor hovers at top
    Variants {
        model: Quickshell.screens
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
                // When notch is hidden, only the top trigger hotspot is masked.
                // When notch is visible, the entire island receives pointer input.
                mask: Region {
                    item: Config.notchVisible ? island : topTrigger
                }

                // Top Edge Indicator Line & Trigger Hotspot
                Item {
                    id: topTrigger
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: island.implicitWidth
                    height: 10

                    // Sleek Apple home-bar/notch indicator line at the top screen bezel
                    Rectangle {
                        id: indicatorLine
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 140
                        height: 3
                        bottomLeftRadius: 2
                        bottomRightRadius: 2
                        color: triggerHover.hovered ? Config.actBg : Qt.rgba(1, 1, 1, 0.45)
                        opacity: Config.notchVisible ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: 180 }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 160 }
                        }
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    HoverHandler {
                        id: triggerHover
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
