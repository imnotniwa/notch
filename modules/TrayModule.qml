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

                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: mouseArea.containsMouse ? Qt.rgba(Config.hvrBg.r, Config.hvrBg.g, Config.hvrBg.b, 0.25) : "transparent"

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
                        if (mouse.button === Qt.RightButton) {
                            if (trayItemContainer.modelData.hasMenu && trayItemContainer.modelData.menu) {
                                if (Config.trayMenuVisible && Config.trayActiveMenu === trayItemContainer.modelData.menu) {
                                    Config.trayMenuVisible = false;
                                } else {
                                    let pt = trayItemContainer.mapToItem(null, 0, 0);
                                    Config.trayMenuX = Math.round(pt.x - 40);
                                    Config.trayMenuY = Config.expandedHeight + 4;
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
                                    let pt = trayItemContainer.mapToItem(null, 0, 0);
                                    Config.trayMenuX = Math.round(pt.x - 40);
                                    Config.trayMenuY = Config.expandedHeight + 4;
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
                    anchors.top: trayItemContainer.bottom
                    anchors.topMargin: 6
                    anchors.horizontalCenter: trayItemContainer.horizontalCenter
                }
            }
        }
    }
}
