import QtQuick
import QtQuick.Layouts
import "../modules"
import ".."

Item {
    id: root

    implicitWidth: 540
    implicitHeight: 132

    readonly property var tabModel: [
        { name: "Media", icon: "" },
        { name: "Spaces", icon: "" },
        { name: "Hardware", icon: "󰍛" },
        { name: "Control", icon: "󰒓" },
        { name: "Tray", icon: "󰀻" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // =====================================================================
        // TOP HEADER: Tabs / Gallery Switcher (Reference 1 & 2)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 8

            // Gallery Navigation Tabs (Reference 2: Nook, Tray, etc.)
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: root.tabModel

                    Rectangle {
                        id: tabBtn
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: Config.galleryIndex === index
                        implicitWidth: 26
                        implicitHeight: 22
                        radius: 11
                        color: isSelected ? Qt.rgba(1, 1, 1, 0.16) : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                        border.color: isSelected ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: tabBtn.modelData.icon
                            color: tabBtn.isSelected ? Config.actFg : Config.dimFg
                            font.family: Config.iconFont
                            font.pixelSize: 12
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

            Item { Layout.fillWidth: true } // Spacer

            // Previous / Next Gallery Nav Arrows (User request)
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: prevNavM.pressed ? Qt.rgba(1, 1, 1, 0.22) : (prevNavM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: prevNavM.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    scale: prevNavM.pressed ? 0.90 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: prevNavM.pressed ? 60 : 180; easing.type: prevNavM.pressed ? Easing.OutQuad : Easing.OutBack; easing.overshoot: 1.15 }
                    }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: prevNavM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.galleryIndex = (Config.galleryIndex - 1 + root.tabModel.length) % root.tabModel.length;
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: nextNavM.pressed ? Qt.rgba(1, 1, 1, 0.22) : (nextNavM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: nextNavM.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    scale: nextNavM.pressed ? 0.90 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: nextNavM.pressed ? 60 : 180; easing.type: nextNavM.pressed ? Easing.OutQuad : Easing.OutBack; easing.overshoot: 1.15 }
                    }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: nextNavM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.galleryIndex = (Config.galleryIndex + 1) % root.tabModel.length;
                        }
                    }
                }
            }

            // Power Settings shortcut
            IslandButton {
                icon: ""
                textColor: Config.danger
                hoverBgColor: Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.16)
                onClicked: {
                    Config.powerModalVisible = true;
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
        }

        // =====================================================================
        // ACTIVE GALLERY CARD CONTENT
        // Use StackLayout to strictly mount and activate only the selected card
        // =====================================================================
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: Config.galleryIndex

            MediaDeckCard {}
            SpacesDeckCard {}
            HardwareDeckCard {}
            ControlDeckCard {}
            TrayDeckCard {}
        }
    }
}
