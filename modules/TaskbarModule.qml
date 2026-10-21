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
            if (event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow" || event.name === "activewindow" || event.name === "windowtitle" || event.name === "fullscreen") {
                Hyprland.refreshToplevels();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
    }

    Timer {
        interval: 10000
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
                implicitHeight: 22
                radius: 11
                Layout.alignment: Qt.AlignVCenter

                scale: mouse.pressed ? 0.92 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: mouse.pressed ? 60 : 180
                        easing.type: mouse.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                color: isActive ? Config.actBg : (mouse.pressed ? Qt.rgba(1, 1, 1, 0.18) : (mouse.containsMouse ? Config.hvrBg : Qt.rgba(1, 1, 1, 0.06)))
                border.color: isActive ? "transparent" : (mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                border.width: 1
                clip: true

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (evt) => {
                        if (evt.button === Qt.LeftButton) {
                            if (Config.appMenuVisible) Config.appMenuVisible = false;
                            HyprlandLua.focusWindow(taskItem.modelData.address);
                        } else if (evt.button === Qt.RightButton) {
                            let pt = taskItem.mapToItem(null, 0, 0);
                            let targetX = Math.round(pt.x - 20);

                            if (Config.appMenuVisible && Config.activeAppWindow === taskItem.modelData) {
                                Config.appMenuVisible = false;
                                Config.activeAppWindow = null;
                            } else {
                                Config.appMenuX = targetX;
                                Config.activeAppWindow = {
                                    address: taskItem.modelData.address,
                                    title: taskItem.windowTitle,
                                    appClass: taskItem.appClass
                                };
                                Config.appMenuVisible = true;
                            }
                        }
                    }
                }

                StyledTooltip {
                    text: taskItem.windowTitle
                    visible: mouse.containsMouse && !taskItem.isActive && !Config.appMenuVisible
                    anchors.horizontalCenter: taskItem.horizontalCenter
                    y: Config.activeAnchorEdge === "bottom" ? (-height - 8) : (taskItem.height + 8)
                }
            }
        }
    }
}
