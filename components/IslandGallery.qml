import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 260

    readonly property var tabModel: [
        { name: "Home", icon: "" },
        { name: "Media", icon: "" },
        { name: "Spaces", icon: "󰍺" },
        { name: "Hardware", icon: "󰘚" },
        { name: "Control", icon: "󰘮" },
        { name: "Tray", icon: "󰇘" },
        { name: "Tasks", icon: "󰄱" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // =====================================================================
        // TOP HEADER: Capsules & Utilities (from Reference)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 10

            // Left Pill Capsule: Menu Navigation Tabs (Home, Media, etc.)
            Rectangle {
                implicitHeight: 30
                implicitWidth: navRow.implicitWidth + 8
                radius: 15
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: navRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: root.tabModel

                        Rectangle {
                            id: tabBtn
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: Config.galleryIndex === index
                            implicitHeight: 24
                            // Active tab expands horizontally to show icon + name
                            implicitWidth: isSelected ? (tabContent.implicitWidth + 16) : 26
                            radius: 12
                            color: isSelected ? Qt.rgba(1, 1, 1, 0.20) : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            border.color: isSelected ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                            border.width: 1

                            Behavior on implicitWidth {
                                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                            }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            RowLayout {
                                id: tabContent
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: tabBtn.modelData.icon
                                    color: tabBtn.isSelected ? Config.actFg : Config.dimFg
                                    font.family: Config.iconFont
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: tabBtn.modelData.name
                                    color: Config.mainFg
                                    font.family: Config.bodyFont
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    visible: tabBtn.isSelected
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.galleryIndex = tabBtn.index;
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Right Pill Capsule: Battery & Quick Utility Buttons
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // Battery Pill
                BatteryModule {
                    compactMode: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Volume / Audio Quick Pill
                AudioModule {
                    compactMode: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Caffeine Toggle
                CaffeineModule {
                    Layout.alignment: Qt.AlignVCenter
                }

                // Notification History Modal Button (bell icon with unread badge)
                IslandButton {
                    icon: "󰂚"
                    active: Config.notificationModalVisible
                    textColor: Config.notificationHistory.length > 0 ? Config.actFg : Config.dimFg
                    onClicked: {
                        Config.notificationModalVisible = !Config.notificationModalVisible;
                    }
                }

                // Settings Card Button (cog icon)
                IslandButton {
                    icon: "󰒓"
                    active: Config.galleryIndex === 7
                    onClicked: {
                        if (Config.galleryIndex === 7) {
                            Config.galleryIndex = 0;
                        } else {
                            Config.galleryIndex = 7;
                        }
                    }
                }

                // Pin Button
                IslandButton {
                    icon: Config.isPinned ? "󰐃" : "󰤱"
                    active: Config.isPinned
                    onClicked: {
                        Config.isPinned = !Config.isPinned;
                        if (!Config.isPinned) {
                            Config.isDeckOpen = false;
                        }
                    }
                }

                // Power Modal Trigger (lock/power icon)
                IslandButton {
                    icon: "󰌾"
                    textColor: Config.dimFg
                    hoverBgColor: Qt.rgba(1, 1, 1, 0.12)
                    onClicked: {
                        Config.powerModalVisible = true;
                    }
                }
            }
        }

        // =====================================================================
        // ACTIVE GALLERY CARD CONTENT
        // =====================================================================
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: Config.galleryIndex

            // Index 0: New Home Dashboard (Now Playing + Calendar + Up Next)
            HomeDeckCard {}

            // Index 1: Media
            MediaDeckCard {}

            // Index 2: Workspaces / Spaces
            SpacesDeckCard {}

            // Index 3: Hardware / SysMon
            HardwareDeckCard {}

            // Index 4: Control Center
            ControlDeckCard {}

            // Index 5: Tray
            TrayDeckCard {}

            // Index 6: Dedicated Tasks & Reminders
            TodoDeckCard {}

            // Index 7: Settings
            SettingsDeckCard {}
        }
    }
}
