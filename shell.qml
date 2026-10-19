import QtQuick
import Quickshell
import "components"
import "."

ShellRoot {
    // Top Bar Window per screen
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

                // Window height provides space for resting and expanded island
                implicitHeight: 64
                color: "transparent"

                // Space reserved for tiling windows
                exclusiveZone: Config.expanded ? Config.expandedHeight + 4 : Config.compactHeight + 4

                // Click-through mask: clicks outside the island pass directly to windows/desktop underneath
                mask: Region {
                    item: island
                }

                Island {
                    id: island
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // Centered Modal Window per screen (mapped when powerModalVisible is true)
    Variants {
        model: Quickshell.screens
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

                PowerModal {}
            }
        }
    }
}
