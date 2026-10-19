import QtQuick
import Quickshell
import "components"
import "."

ShellRoot {
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
}
