import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 24

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow" || event.name === "activewindow") {
                Hyprland.refreshToplevels();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            Hyprland.refreshToplevels();
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: Hyprland.toplevels

            Rectangle {
                id: taskItem
                required property var modelData
                
                readonly property string appClass: (modelData.lastIpcObject && modelData.lastIpcObject.class) ? modelData.lastIpcObject.class : ""
                readonly property string windowTitle: modelData.title || appClass || "App"
                readonly property bool isActive: modelData.activated

                implicitWidth: isActive ? Math.min(titleText.implicitWidth + 30, 160) : 26
                implicitHeight: 24
                radius: 12
                color: isActive ? Config.actBg : (mouse.containsMouse ? Qt.rgba(Config.hvrBg.r, Config.hvrBg.g, Config.hvrBg.b, 0.25) : Qt.rgba(1, 1, 1, 0.07))
                clip: true

                Behavior on implicitWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    IconImage {
                        source: taskItem.appClass !== "" ? Quickshell.iconPath(taskItem.appClass.toLowerCase()) : ""
                        implicitWidth: 14
                        implicitHeight: 14
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        id: titleText
                        visible: taskItem.isActive
                        text: taskItem.windowTitle
                        color: taskItem.isActive ? Config.actFg : Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (evt) => {
                        if (evt.button === Qt.LeftButton) {
                            HyprlandLua.focusWindow(taskItem.modelData.address);
                        } else if (evt.button === Qt.RightButton) {
                            HyprlandLua.fullscreenWindow();
                        } else if (evt.button === Qt.MiddleButton) {
                            HyprlandLua.closeWindow(taskItem.modelData.address);
                        }
                    }
                }

                StyledTooltip {
                    text: taskItem.windowTitle
                    visible: mouse.containsMouse && !taskItem.isActive
                    anchors.top: taskItem.bottom
                    anchors.topMargin: 6
                    anchors.horizontalCenter: taskItem.horizontalCenter
                }
            }
        }
    }
}
