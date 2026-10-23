import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    readonly property int itemCount: SystemTray.items ? SystemTray.items.values.length : 0

    // Adaptive density metrics based on active items count
    // 1-4 apps: 2 columns, roomier height
    // 5-8 apps: 2 columns, standard medium height
    // 9+ apps: 3 columns, compact height
    readonly property int gridColumns: itemCount > 8 ? 3 : 2
    readonly property int cardHeight: itemCount <= 4 ? 64 : (itemCount <= 8 ? 48 : 42)
    readonly property bool isRoomy: itemCount <= 4

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // =====================================================================
        // TOP HEADER: Section Title & Active Counters
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "BACKGROUND APPS & UTILITIES"
                color: Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Rectangle {
                implicitWidth: countText.implicitWidth + 14
                implicitHeight: 20
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.itemCount + (root.itemCount === 1 ? " Active" : " Active")
                    color: Config.mainFg
                    font.family: Config.monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Left-click: Open  •  Right-click: Menu"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.family: Config.bodyFont
                font.pixelSize: 10
                visible: root.itemCount > 0
            }
        }

        // =====================================================================
        // MAIN CONTENT: Scrollable Adaptive Grid or Clean Empty State
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State when no tray applications are running
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                visible: root.itemCount === 0

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 23
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰇘"
                        color: Config.dimFg
                        font.family: Config.iconFont
                        font.pixelSize: 20
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No active tray applications"
                    color: Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Background services and minimized applets will appear here"
                    color: Config.dimFg
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                }
            }

            // Scrollable Grid of Applet Cards
            ScrollView {
                id: trayScrollView
                anchors.fill: parent
                visible: root.itemCount > 0
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    active: trayScrollView.hovered || pressed
                    policy: ScrollBar.AsNeeded
                    width: 4

                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: vbar.pressed ? Qt.rgba(1, 1, 1, 0.40) : (vbar.hovered ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.12))
                    }
                }

                GridLayout {
                    width: trayScrollView.width - (vbar.visible ? 8 : 0)
                    columns: root.gridColumns
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: SystemTray.items

                        Rectangle {
                            id: appCard
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: root.cardHeight
                            radius: 12
                            color: cardMouse.pressed ? Qt.rgba(1, 1, 1, 0.14) : (cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                            border.color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.07)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: root.isRoomy ? 12 : 10
                                spacing: root.isRoomy ? 12 : 10

                                // App Icon Platter
                                Rectangle {
                                    implicitWidth: root.isRoomy ? 38 : 30
                                    implicitHeight: root.isRoomy ? 38 : 30
                                    radius: 8
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    border.color: Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1

                                    IconImage {
                                        anchors.centerIn: parent
                                        source: appCard.modelData.icon || ""
                                        implicitWidth: root.isRoomy ? 22 : 18
                                        implicitHeight: root.isRoomy ? 22 : 18
                                    }
                                }

                                // App Name & Subtext
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: root.isRoomy ? 3 : 1

                                    Text {
                                        text: {
                                            let title = appCard.modelData.title || appCard.modelData.tooltipTitle || "";
                                            if (title) return title;
                                            let idStr = appCard.modelData.id || "";
                                            if (idStr) {
                                                // Humanize camelCase or snake_case
                                                return idStr.replace(/[-_]/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                                            }
                                            return "Application";
                                        }
                                        color: Config.mainFg
                                        font.family: Config.bodyFont
                                        font.pixelSize: root.isRoomy ? 13 : 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: {
                                            let tip = appCard.modelData.tooltipTitle || appCard.modelData.tooltipBody || "";
                                            if (tip && tip !== appCard.modelData.title) return tip;
                                            return appCard.modelData.hasMenu ? "Running (Right-click menu)" : "Active in background";
                                        }
                                        color: Config.dimFg
                                        font.family: Config.bodyFont
                                        font.pixelSize: root.isRoomy ? 11 : 9
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Menu Hint Indicator if app supports context menu
                                Text {
                                    text: "󰅂"
                                    color: Qt.rgba(1, 1, 1, 0.25)
                                    font.family: Config.iconFont
                                    font.pixelSize: 12
                                    visible: appCard.modelData.hasMenu
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: (mouse) => {
                                    let pt = appCard.mapToItem(null, 0, 0);
                                    let targetX = Math.round(pt.x + 20);

                                    if (mouse.button === Qt.RightButton) {
                                        if (appCard.modelData.hasMenu && appCard.modelData.menu) {
                                            if (Config.trayMenuVisible && Config.trayActiveMenu === appCard.modelData.menu) {
                                                Config.trayMenuVisible = false;
                                            } else {
                                                Config.trayMenuX = targetX;
                                                Config.trayActiveMenu = appCard.modelData.menu;
                                                Config.trayMenuVisible = true;
                                            }
                                        } else {
                                            appCard.modelData.secondaryActivate();
                                        }
                                    } else {
                                        if (appCard.modelData.onlyMenu && appCard.modelData.hasMenu && appCard.modelData.menu) {
                                            if (Config.trayMenuVisible && Config.trayActiveMenu === appCard.modelData.menu) {
                                                Config.trayMenuVisible = false;
                                            } else {
                                                Config.trayMenuX = targetX;
                                                Config.trayActiveMenu = appCard.modelData.menu;
                                                Config.trayMenuVisible = true;
                                            }
                                        } else {
                                            appCard.modelData.activate();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
