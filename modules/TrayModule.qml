import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            Rectangle {
                id: trayItemContainer
                required property var modelData

                implicitWidth: 22
                implicitHeight: 22
                radius: 6
                Layout.alignment: Qt.AlignVCenter

                scale: mouseArea.pressed ? 0.90 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: mouseArea.pressed ? 60 : 180
                        easing.type: mouseArea.pressed ? Easing.OutQuad : Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                color: mouseArea.pressed ? Qt.rgba(1, 1, 1, 0.18) : (mouseArea.containsMouse ? Config.hvrBg : "transparent")

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                IconImage {
                    anchors.centerIn: parent
                    source: trayItemContainer.modelData.icon || ""
                    implicitWidth: 14
                    implicitHeight: 14
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        let pt = trayItemContainer.mapToItem(null, 0, 0);
                        let targetX = Math.round(pt.x - 40);

                        if (mouse.button === Qt.RightButton) {
                            if (trayItemContainer.modelData.hasMenu && trayItemContainer.modelData.menu) {
                                if (Config.trayMenuVisible && Config.trayActiveMenu === trayItemContainer.modelData.menu) {
                                    Config.trayMenuVisible = false;
                                } else {
                                    Config.trayMenuX = targetX;
                                    Config.trayActiveMenu = trayItemContainer.modelData.menu;
                                    Config.trayMenuVisible = true;
                                }
                            } else {
                                trayItemContainer.modelData.secondaryActivate();
                            }
                        } else {
                            if (trayItemContainer.modelData.onlyMenu && trayItemContainer.modelData.hasMenu && trayItemContainer.modelData.menu) {
                                if (Config.trayMenuVisible && Config.trayActiveMenu === trayItemContainer.modelData.menu) {
                                    Config.trayMenuVisible = false;
                                } else {
                                    Config.trayMenuX = targetX;
                                    Config.trayActiveMenu = trayItemContainer.modelData.menu;
                                    Config.trayMenuVisible = true;
                                }
                            } else {
                                trayItemContainer.modelData.activate();
                            }
                        }
                    }
                }

                StyledTooltip {
                    text: trayItemContainer.modelData.tooltipTitle || trayItemContainer.modelData.title || ""
                    visible: mouseArea.containsMouse && !Config.trayMenuVisible && text !== ""
                    anchors.top: Config.activeAnchorEdge === "bottom" ? undefined : trayItemContainer.bottom
                    anchors.bottom: Config.activeAnchorEdge === "bottom" ? trayItemContainer.top : undefined
                    anchors.topMargin: Config.activeAnchorEdge === "bottom" ? 0 : 8
                    anchors.bottomMargin: Config.activeAnchorEdge === "bottom" ? 8 : 0
                    anchors.horizontalCenter: trayItemContainer.horizontalCenter
                }
            }
        }
    }
}
