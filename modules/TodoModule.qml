import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 280
    implicitHeight: 228

    readonly property var accentColors: [
        "#af52de", // Purple
        "#34c759", // Green
        "#0071e3", // Blue
        "#ff9f0a", // Orange
        "#ff2d55", // Pink
        "#5856d6"  // Indigo
    ]

    function getColorForIndex(idx) {
        return accentColors[idx % accentColors.length];
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Header: UP NEXT with badge count and + New button
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "UP NEXT"
                color: Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Rectangle {
                implicitWidth: badgeText.implicitWidth + 10
                implicitHeight: 16
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: TodoService.pendingCount.toString()
                    color: Config.mainFg
                    font.family: Config.monoFont
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            // + Add Button (Opens TodoAddModal)
            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: homeAddM.containsMouse ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                border.color: homeAddM.containsMouse ? Config.actBg : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: homeAddM.containsMouse ? Config.actFg : Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: homeAddM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.todoModalVisible = true;
                    }
                }
            }

            Text {
                text: "All 󰄱"
                color: tabHintMouse.containsMouse ? Config.actFg : Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    id: tabHintMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.galleryIndex = 6; // Switch to Tasks tab
                    }
                }
            }
        }

        // Clean Reference-Style List (Matching Reference UP NEXT items)
        ListView {
            id: todoListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: TodoService.homeTodos

            displaced: Transition {
                NumberAnimation { properties: "y,opacity"; duration: 250; easing.type: Easing.OutCubic }
            }

            delegate: Item {
                id: itemRow
                required property var modelData
                required property int index
                width: ListView.view.width
                implicitHeight: 34

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Checkbox Circle
                    Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: itemRow.modelData.completed ? Config.actBg : "transparent"
                        border.color: itemRow.modelData.completed ? Config.actBg : Qt.rgba(1, 1, 1, 0.28)
                        border.width: 1.5
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            visible: itemRow.modelData.completed
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TodoService.toggleTask(itemRow.modelData.id)
                        }
                    }

                    // Vertical colored accent bar (matches Reference)
                    Rectangle {
                        implicitWidth: 3
                        implicitHeight: 28
                        radius: 1.5
                        color: itemRow.modelData.completed ? Qt.rgba(1, 1, 1, 0.2) : root.getColorForIndex(itemRow.index)
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    // Title & Time in clean hierarchy
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: itemRow.modelData.text
                            color: itemRow.modelData.completed ? Config.dimFg : Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.strikeout: itemRow.modelData.completed
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            opacity: itemRow.modelData.completed ? 0.45 : 1.0

                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: itemRow.modelData.time || "Today"
                                color: Config.dimFg
                                font.family: Config.bodyFont
                                font.pixelSize: 10
                                font.weight: Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                opacity: itemRow.modelData.completed ? 0.35 : 0.8
                            }

                            Text {
                                text: "Done"
                                color: Config.success
                                font.family: Config.bodyFont
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                visible: itemRow.modelData.completed
                            }
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                    onClicked: TodoService.toggleTask(itemRow.modelData.id)
                }
            }

            Text {
                anchors.centerIn: parent
                text: "All caught up! 🎉"
                color: Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 12
                visible: TodoService.homeTodos.length === 0
            }
        }
    }
}
