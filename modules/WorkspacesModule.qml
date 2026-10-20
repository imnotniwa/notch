import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Track active workspace ID
    property int activeWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // Workspaces 1..5 minimum, or higher if occupied
    property var workspaceList: [1, 2, 3, 4, 5]

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "focusedmon" || event.name === "createworkspace" || event.name === "destroyworkspace") {
                Hyprland.refreshWorkspaces();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces();
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            Hyprland.refreshWorkspaces();
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.workspaceList

            Rectangle {
                id: wsBtn
                required property int modelData
                readonly property bool isCurrent: root.activeWorkspaceId === modelData
                
                // Apple fluid morphing capsule
                implicitWidth: isCurrent ? 28 : 22
                implicitHeight: 22
                radius: 11
                Layout.alignment: Qt.AlignVCenter

                // Apple tactile feedback: instant press scale down, spring back
                scale: wsMouse.pressed ? 0.90 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: wsMouse.pressed ? 60 : 180
                        easing.type: wsMouse.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                // Apple Material Hierarchy: Active Vibrant Blue, Hover Frosted Glass, Inactive Translucent Sub-pill
                color: isCurrent ? Config.actBg : (wsMouse.pressed ? Qt.rgba(1, 1, 1, 0.18) : (wsMouse.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06)))
                border.color: isCurrent ? "transparent" : (wsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsBtn.modelData.toString()
                    color: wsBtn.isCurrent ? Config.actFg : (wsMouse.containsMouse ? Config.hvrFg : Config.mainFg)
                    font.family: Config.monoFontFamily
                    font.pixelSize: Config.fontSize
                    font.weight: wsBtn.isCurrent ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        HyprlandLua.focusWorkspace(wsBtn.modelData);
                    }

                    onWheel: (wheel) => {
                        HyprlandLua.cycleWorkspace(wheel.angleDelta.y < 0);
                    }
                }
            }
        }
    }
}
