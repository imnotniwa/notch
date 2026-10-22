import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../core"
import ".."

Item {
    id: root

    anchors.fill: parent
    focus: true

    readonly property var history: Config.notificationHistory || []

    Keys.onEscapePressed: {
        Config.notificationModalVisible = false;
    }

    Component.onCompleted: {
        root.forceActiveFocus();
        modalCard.scale = 0.92;
        modalCard.opacity = 0;
        openAnim.start();
    }

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus();
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
            easing.overshoot: 1.06
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
                Config.notificationModalVisible = false;
            }
        }
    }

    // Centered Apple Modal Card
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: 520
        height: 480
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
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // =================================================================
            // HEADER BAR: Title, Unread Count, Action Controls, Close
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Notification Bell Icon & Title
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        font.family: Config.iconFont
                        font.pixelSize: 13
                        color: Config.actFg
                    }
                }

                Text {
                    text: "Notification Center"
                    font.family: Config.bodyFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Config.mainFg
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    implicitWidth: countText.implicitWidth + 12
                    implicitHeight: 18
                    radius: 9
                    color: root.history.length > 0 ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: root.history.length > 0 ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.35) : "transparent"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.history.length
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: root.history.length > 0 ? Config.actFg : Config.dimFg
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                // Clear All Button
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: clearAllText.implicitWidth + 16
                    radius: 12
                    color: clrAllMouse.pressed ? Qt.rgba(1, 1, 1, 0.22) : (clrAllMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.07))
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: 1
                    visible: root.history.length > 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: clearAllText
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Config.dimFg
                    }

                    MouseArea {
                        id: clrAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.clearHistory();
                        }
                    }
                }

                // Close Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: closeM.pressed ? Qt.rgba(1, 1, 1, 0.24) : (closeM.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08))
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        color: Config.mainFg
                    }

                    MouseArea {
                        id: closeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.notificationModalVisible = false;
                        }
                    }
                }
            }

            // =================================================================
            // MAIN NOTIFICATION LIST (Spacious, Multi-line, Scrollable)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.03)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                clip: true

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.history.length === 0

                    Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.05)
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: Config.iconFont
                            font.pixelSize: 22
                            color: Qt.rgba(1, 1, 1, 0.25)
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No Notifications Yet"
                        font.family: Config.bodyFont
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Config.mainFg
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Incoming notifications and test alerts will appear here."
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        color: Config.dimFg
                    }
                }

                // Scrollable List
                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    clip: true
                    visible: root.history.length > 0
                    model: root.history

                    delegate: Rectangle {
                        id: itemRow
                        required property var modelData
                        required property int index

                        width: listView.width
                        implicitHeight: cardContent.implicitHeight + 16
                        radius: 12
                        color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                        border.color: itemRow.modelData.urgency === 2 ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.40) : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                        border.width: 1

                        ColumnLayout {
                            id: cardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 4

                            // Top row: App icon, app name, time, urgency badge
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 10
                                    color: itemRow.modelData.urgency === 2 ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.25) : (itemRow.modelData.badgeColor ? itemRow.modelData.badgeColor : Qt.rgba(1, 1, 1, 0.12))

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: itemRow.modelData.appIcon ? Quickshell.iconPath(itemRow.modelData.appIcon) : ""
                                        visible: source != ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: itemRow.modelData.urgency === 2 ? "󰀦" : (itemRow.modelData.badgeIcon ? itemRow.modelData.badgeIcon : "󰂚")
                                        font.family: Config.iconFont
                                        font.pixelSize: 10
                                        color: itemRow.modelData.urgency === 2 ? Config.danger : "#ffffff"
                                        visible: !itemRow.modelData.appIcon || !parent.children[0].visible
                                    }
                                }

                                Text {
                                    text: itemRow.modelData.appName || "Notification"
                                    font.family: Config.bodyFont
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Config.mainFg
                                }

                                Rectangle {
                                    implicitHeight: 16
                                    implicitWidth: catTag.implicitWidth + 8
                                    radius: 8
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    visible: itemRow.modelData.category && itemRow.modelData.category !== ""

                                    Text {
                                        id: catTag
                                        anchors.centerIn: parent
                                        text: itemRow.modelData.category ? itemRow.modelData.category.toUpperCase() : ""
                                        font.family: Config.bodyFont
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: Config.dimFg
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: itemRow.modelData.time || ""
                                    font.family: Config.bodyFont
                                    font.pixelSize: 10
                                    color: Config.dimFg
                                }
                            }

                            // Summary / Title
                            Text {
                                text: itemRow.modelData.summary || ""
                                font.family: Config.bodyFont
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: itemRow.modelData.urgency === 2 ? Config.danger : Config.mainFg
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            // Body Message
                            Text {
                                text: itemRow.modelData.body || ""
                                font.family: Config.bodyFont
                                font.pixelSize: 11
                                color: Config.dimFg
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                visible: text !== ""
                            }

                            // Action Pills
                            RowLayout {
                                spacing: 6
                                visible: itemRow.modelData.actions && itemRow.modelData.actions.length > 0
                                Layout.topMargin: 4

                                Repeater {
                                    model: itemRow.modelData.actions || []
                                    delegate: Rectangle {
                                        required property var modelData
                                        implicitHeight: 22
                                        implicitWidth: actBtnText.implicitWidth + 14
                                        radius: 11
                                        color: actBtnMouse.pressed ? Qt.rgba(1, 1, 1, 0.28) : (actBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10))
                                        border.color: Qt.rgba(1, 1, 1, 0.12)
                                        border.width: 1

                                        Text {
                                            id: actBtnText
                                            anchors.centerIn: parent
                                            text: modelData.text || modelData.identifier
                                            font.family: Config.bodyFont
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: Config.mainFg
                                        }

                                        MouseArea {
                                            id: actBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                NotificationService.invokeAction(itemRow.modelData, modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                        }
                    }
                }
            }
        }
    }
}
