import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 600
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
        spacing: 12

        // Top Header: Title, Counters, Add & Clear Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "UP NEXT"
                color: Config.dimFg
                font.family: Config.bodyFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }

            Rectangle {
                implicitWidth: statsText.implicitWidth + 12
                implicitHeight: 20
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: statsText
                    anchors.centerIn: parent
                    text: TodoService.pendingCount + " pending"
                    color: Config.dimFg
                    font.family: Config.bodyFont
                    font.pixelSize: 10
                }
            }

            Item { Layout.fillWidth: true }

            // Add Task Button (Opens Modal)
            Rectangle {
                implicitWidth: addBtnText.implicitWidth + 20
                implicitHeight: 24
                radius: 12
                color: addBtnM.pressed ? Qt.darker(Config.actBg, 1.2) : (addBtnM.containsMouse ? Qt.lighter(Config.actBg, 1.1) : Config.actBg)

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "+"
                        color: "#ffffff"
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    Text {
                        id: addBtnText
                        text: "New Item"
                        color: "#ffffff"
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: addBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.todoModalVisible = true;
                    }
                }
            }

            // Clear Completed Button
            Rectangle {
                implicitWidth: clearAllText.implicitWidth + 14
                implicitHeight: 24
                radius: 12
                color: clearAllM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (clearAllM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                visible: TodoService.completedCount > 0

                Text {
                    id: clearAllText
                    anchors.centerIn: parent
                    text: "Clear Done"
                    color: Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: clearAllM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TodoService.clearCompleted()
                }
            }
        }

        // Clean Reference-Style List (No heavy bordered boxes)
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            model: TodoService.todos

            delegate: Item {
                id: cardRow
                required property var modelData
                required property int index
                width: ListView.view.width
                implicitHeight: 38
                readonly property bool hovered: rowMouse.containsMouse || cardDelM.containsMouse

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Checkbox Circle
                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        color: cardRow.modelData.completed ? Config.actBg : "transparent"
                        border.color: cardRow.modelData.completed ? Config.actBg : Qt.rgba(1, 1, 1, 0.3)
                        border.width: 1.5
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            visible: cardRow.modelData.completed
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TodoService.toggleTask(cardRow.modelData.id)
                        }
                    }

                    // Vertical colored accent bar (matches Reference)
                    Rectangle {
                        implicitWidth: 3.5
                        implicitHeight: 32
                        radius: 1.75
                        color: cardRow.modelData.completed ? Qt.rgba(1, 1, 1, 0.2) : root.getColorForIndex(cardRow.index)
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    // Title & Time in clean vertical layout
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: cardRow.modelData.text
                            color: cardRow.modelData.completed ? Config.dimFg : Config.mainFg
                            font.family: Config.bodyFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.strikeout: cardRow.modelData.completed
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            opacity: cardRow.modelData.completed ? 0.45 : 1.0

                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        Text {
                            text: cardRow.modelData.time || "Today"
                            color: Config.dimFg
                            font.family: Config.bodyFont
                            font.pixelSize: 11
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            opacity: cardRow.modelData.completed ? 0.35 : 0.85
                        }
                    }

                    // Delete button: generous hit area and higher z-order
                    Item {
                        implicitWidth: 32
                        implicitHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        z: 10

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            color: cardDelM.pressed ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.35) : (cardDelM.containsMouse ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.20) : (cardRow.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"))
                            scale: cardDelM.pressed ? 0.90 : 1.0

                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: cardDelM.containsMouse ? Config.danger : Config.dimFg
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: cardDelM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                TodoService.deleteTask(cardRow.modelData.id);
                            }
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                    onClicked: TodoService.toggleTask(cardRow.modelData.id)
                }
            }
        }
    }
}
