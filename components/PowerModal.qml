import QtQuick
import QtQuick.Layouts
import "../core"
import ".."

Item {
    id: root

    // States: "menu", "confirm_shutdown", "confirm_reboot", "confirm_logout"
    property string viewState: "menu"

    anchors.fill: parent

    Component.onCompleted: {
        root.viewState = "menu";
        modalCard.scale = 0.92;
        modalCard.opacity = 0;
        openAnim.start();
    }

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
            duration: 240
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }
        NumberAnimation {
            target: modalCard
            property: "opacity"
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Fullscreen Dimmed Backdrop (Apple Scrim)
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
        width: 360
        implicitHeight: contentColumn.implicitHeight + 44
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
            width: parent.width - 44
            spacing: 16

            // ==========================================
            // 1. MAIN MENU VIEW
            // ==========================================
            ColumnLayout {
                visible: root.viewState === "menu"
                Layout.fillWidth: true
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Power Options"
                            color: Config.mainFg
                            font.family: Config.fontFamily
                            font.pixelSize: 13
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

                    // Close Button (Apple circular dismiss)
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        border.width: 1

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "close"
                            implicitWidth: 12
                            implicitHeight: 12
                            strokeWidth: 2.2
                            color: closeMouse.containsMouse ? Config.hvrFg : Config.mainFg
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.powerModalVisible = false;
                            }
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

                    // 1. Lock Screen
                    Rectangle {
                        id: lockBtnCard
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        scale: lockMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: lockMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: lockMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.40) : Config.subPillBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Left fixed icon slot
                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                SvgIcon {
                                    anchors.centerIn: parent
                                    name: "lock"
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    strokeWidth: 2.0
                                    color: Config.actFg
                                }
                            }

                            // Left-anchored text column
                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

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

                    // 2. Sleep / Suspend
                    Rectangle {
                        id: sleepBtnCard
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        scale: sleepMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: sleepMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: sleepMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.40) : Config.subPillBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Left fixed icon slot
                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                SvgIcon {
                                    anchors.centerIn: parent
                                    name: "sleep"
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    strokeWidth: 2.0
                                    color: Config.actFg
                                }
                            }

                            // Left-anchored text column
                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

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

                    // 3. Log Out
                    Rectangle {
                        id: logoutBtnCard
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        scale: logoutMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: logoutMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Config.subPillBg
                        border.color: logoutMouse.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.40) : Config.subPillBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Left fixed icon slot
                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                SvgIcon {
                                    anchors.centerIn: parent
                                    name: "logout"
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    strokeWidth: 2.0
                                    color: Config.actFg
                                }
                            }

                            // Left-anchored text column
                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

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

                    // 4. Restart
                    Rectangle {
                        id: rebootBtnCard
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        scale: rebootMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: rebootMouse.containsMouse ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.22) : Config.subPillBg
                        border.color: rebootMouse.containsMouse ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.40) : Config.subPillBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Left fixed icon slot
                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                SvgIcon {
                                    anchors.centerIn: parent
                                    name: "restart"
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    strokeWidth: 2.0
                                    color: Config.warning
                                }
                            }

                            // Left-anchored text column
                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

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

                    // 5. Shut Down
                    Rectangle {
                        id: shutdownBtnCard
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        scale: shutdownMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: shutdownMouse.containsMouse ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.22) : Config.subPillBg
                        border.color: shutdownMouse.containsMouse ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.40) : Config.subPillBorder
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            // Left fixed icon slot
                            Item {
                                width: 22
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter

                                SvgIcon {
                                    anchors.centerIn: parent
                                    name: "power"
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    strokeWidth: 2.0
                                    color: Config.danger
                                }
                            }

                            // Left-anchored text column
                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

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

            // ==========================================
            // 2. CONFIRMATION VIEW (Apple Safety & Agency)
            // ==========================================
            ColumnLayout {
                visible: root.viewState !== "menu"
                Layout.fillWidth: true
                spacing: 16

                // Centered Action Badge
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: root.viewState === "confirm_shutdown" ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.20) : (root.viewState === "confirm_reboot" ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.20) : Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.20))
                    border.color: root.viewState === "confirm_shutdown" ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.35) : (root.viewState === "confirm_reboot" ? Qt.rgba(Config.warning.r, Config.warning.g, Config.warning.b, 0.35) : Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.35))
                    border.width: 1

                    SvgIcon {
                        anchors.centerIn: parent
                        name: root.viewState === "confirm_shutdown" ? "power" : (root.viewState === "confirm_reboot" ? "restart" : "logout")
                        implicitWidth: 26
                        implicitHeight: 26
                        strokeWidth: 2.2
                        color: root.viewState === "confirm_shutdown" ? Config.danger : (root.viewState === "confirm_reboot" ? Config.warning : Config.actFg)
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

                // Symmetrical Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Cancel Button
                    Rectangle {
                        id: cancelBtn
                        Layout.fillWidth: true
                        height: 42
                        radius: 12
                        scale: cancelMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Config.subPillBg
                        border.color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Config.subPillBorder
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
                        height: 42
                        radius: 12
                        scale: confirmMouse.pressed ? 0.96 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
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
