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
        interval: 1000
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
                
                // Animated pill expansion for active workspace matching waybar
                implicitWidth: isCurrent ? 28 : 20
                implicitHeight: 20
                radius: 10

                // Apple tactile feedback: scale on press, spring back
                scale: wsMouse.pressed ? 0.90 : (wsMouse.containsMouse ? 1.05 : 1.0)
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: wsMouse.pressed ? 60 : 200
                        easing.type: wsMouse.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                color: isCurrent ? Config.actBg : (wsMouse.containsMouse ? Qt.rgba(Config.hvrBg.r, Config.hvrBg.g, Config.hvrBg.b, 0.3) : Qt.rgba(1, 1, 1, 0.08))

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.toString()
                    color: wsBtn.isCurrent ? Config.actFg : (wsMouse.containsMouse ? Config.hvrFg : Config.mainFg)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: wsBtn.isCurrent
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
