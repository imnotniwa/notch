import QtQuick
import QtQuick.Layouts
import "../core"
import ".."

Item {
    id: root

    // States: "menu", "confirm_shutdown", "confirm_reboot", "confirm_logout"
    property string viewState: "menu"

    anchors.fill: parent

    // Reset view state whenever modal is opened
    onVisibleChanged: {
        if (visible) {
            root.viewState = "menu";
            modalCard.scale = 0.92;
            modalCard.opacity = 0;
            openAnim.start();
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: modalCard
            property: "scale"
            to: 1.0
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: modalCard
            property: "opacity"
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Dimmed Backdrop: Clicking outside closes modal
    Rectangle {
        anchors.fill: parent
        color: "#80000000"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Config.powerModalVisible = false;
            }
        }
    }

    // Modal Card
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: 380
        implicitHeight: contentColumn.implicitHeight + 48
        radius: 20
        color: Config.islandBg
        border.color: Config.islandBorder
        border.width: 1

        // Consume clicks so backdrop doesn't trigger
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            // 1. MAIN MENU VIEW
            ColumnLayout {
                visible: root.viewState === "menu"
                Layout.fillWidth: true
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: "Power Options"
                            color: Config.mainFg
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            text: "Select a session action"
                            color: Config.dimFg
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close Button
                    IslandButton {
                        icon: "󰅖"
                        tooltip: "Close"
                        onClicked: {
                            Config.powerModalVisible = false;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.islandBorder
                }

                // Action Buttons List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Lock Button
                    Rectangle {
                        id: lockBtnCard
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        scale: lockMouse.pressed ? 0.97 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: lockMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: lockMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.4) : Config.subPillBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: "󰌾"
                                color: Config.actFg
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: "Lock Screen"
                                    color: Config.mainFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "Lock session using hyprlock"
                                    color: Config.dimFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: lockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.powerModalVisible = false;
                                HyprlandLua.lock();
                            }
                        }
                    }

                    // Sleep / Suspend Button
                    Rectangle {
                        id: sleepBtnCard
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        scale: sleepMouse.pressed ? 0.97 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: sleepMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: sleepMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.4) : Config.subPillBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: "󰒲"
                                color: Config.actFg
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: "Sleep"
                                    color: Config.mainFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "Suspend system into low power state"
                                    color: Config.dimFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: sleepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.powerModalVisible = false;
                                Config.run("systemctl suspend");
                            }
                        }
                    }

                    // Logout Button
                    Rectangle {
                        id: logoutBtnCard
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        scale: logoutMouse.pressed ? 0.97 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: logoutMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: logoutMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.4) : Config.subPillBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: "󰗽"
                                color: Config.actFg
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: "Log Out"
                                    color: Config.mainFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "Exit Hyprland session"
                                    color: Config.dimFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: logoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewState = "confirm_logout";
                            }
                        }
                    }

                    // Reboot Button
                    Rectangle {
                        id: rebootBtnCard
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        scale: rebootMouse.pressed ? 0.97 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: rebootMouse.containsMouse ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.22) : Config.subPillBg
                        border.color: rebootMouse.containsMouse ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.4) : Config.subPillBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: "󰜉"
                                color: Config.warning
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: "Restart"
                                    color: Config.mainFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "Reboot computer"
                                    color: Config.dimFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: rebootMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewState = "confirm_reboot";
                            }
                        }
                    }

                    // Shutdown Button
                    Rectangle {
                        id: shutdownBtnCard
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        scale: shutdownMouse.pressed ? 0.97 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: shutdownMouse.containsMouse ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.22) : Config.subPillBg
                        border.color: shutdownMouse.containsMouse ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.4) : Config.subPillBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: ""
                                color: Config.danger
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    text: "Shut Down"
                                    color: Config.mainFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                Text {
                                    text: "Turn off computer safely"
                                    color: Config.dimFg
                                    font.family: Config.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            id: shutdownMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewState = "confirm_shutdown";
                            }
                        }
                    }
                }
            }

            // 2. CONFIRMATION VIEW (Shutdown / Reboot / Logout)
            ColumnLayout {
                visible: root.viewState !== "menu"
                Layout.fillWidth: true
                spacing: 16

                // Big Warning / Action Icon
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 52
                    height: 52
                    radius: 26
                    color: root.viewState === "confirm_shutdown" ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.2) : (root.viewState === "confirm_reboot" ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.2) : Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.2))

                    Text {
                        anchors.centerIn: parent
                        text: root.viewState === "confirm_shutdown" ? "" : (root.viewState === "confirm_reboot" ? "󰜉" : "󰗽")
                        color: root.viewState === "confirm_shutdown" ? Config.danger : (root.viewState === "confirm_reboot" ? Config.warning : Config.actFg)
                        font.family: Config.fontFamily
                        font.pixelSize: 22
                    }
                }

                // Confirmation Heading & Subtext
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.viewState === "confirm_shutdown" ? "Shut down your computer?" : (root.viewState === "confirm_reboot" ? "Restart your computer?" : "Log out of session?")
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Make sure all your unsaved work is saved."
                        color: Config.dimFg
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Confirmation Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Cancel
                    Rectangle {
                        id: cancelBtn
                        Layout.fillWidth: true
                        height: 40
                        radius: 10
                        scale: cancelMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Config.subPillBg
                        border.color: Config.subPillBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Config.mainFg
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.viewState = "menu";
                            }
                        }
                    }

                    // Confirm Action Button
                    Rectangle {
                        id: confirmBtn
                        Layout.fillWidth: true
                        height: 40
                        radius: 10
                        scale: confirmMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        color: root.viewState === "confirm_shutdown" ? Config.danger : (root.viewState === "confirm_reboot" ? Config.warning : Config.actBg)

                        Text {
                            anchors.centerIn: parent
                            text: root.viewState === "confirm_shutdown" ? "Shut Down" : (root.viewState === "confirm_reboot" ? "Restart" : "Log Out")
                            color: root.viewState === "confirm_reboot" ? "#191724" : "white"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.powerModalVisible = false;
                                if (root.viewState === "confirm_shutdown") {
                                    HyprlandLua.poweroff();
                                } else if (root.viewState === "confirm_reboot") {
                                    HyprlandLua.reboot();
                                } else if (root.viewState === "confirm_logout") {
                                    HyprlandLua.exit();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
