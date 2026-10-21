import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    GridLayout {
        anchors.fill: parent
        columns: 2
        columnSpacing: 10
        rowSpacing: 8

        // =====================================================================
        // Tile 1: Always On Notch (Compact Glance Persistence)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            MouseArea {
                id: alwaysOnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Config.alwaysOn = !Config.alwaysOn;
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 10

                // Icon Capsule
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Config.alwaysOn ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Config.alwaysOn ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.4) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰍹"
                        font.family: Config.iconFont
                        font.pixelSize: 15
                        color: Config.alwaysOn ? Config.actBg : Config.mainFg
                    }
                }

                // Text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Always On Notch"
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Text {
                        text: Config.alwaysOn ? "Compact bar stays on screen" : "Auto-hides when cursor departs"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        color: Config.dimFg
                        elide: Text.ElideRight
                    }
                }

                // Apple Switch Indicator
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 20
                    radius: 10
                    color: Config.alwaysOn ? Config.actBg : Qt.rgba(1, 1, 1, 0.16)
                    border.color: Config.alwaysOn ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 160 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.alwaysOn ? parent.width - width - 3 : 3

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Tile 2: Display Anchor Mode
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 10

                // Icon Capsule
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰉔"
                        font.family: Config.iconFont
                        font.pixelSize: 15
                        color: Config.mainFg
                    }
                }

                // Text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Display Anchor"
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Config.mainFg
                    }

                    Text {
                        text: Config.notchAnchor === "auto" ? "Smart Stack Detection" : (Config.notchAnchor === "top" ? "Forced Top Edge" : "Forced Bottom Edge")
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        color: Config.dimFg
                        elide: Text.ElideRight
                    }
                }

                // 3-Segment Selector
                RowLayout {
                    spacing: 2

                    Repeater {
                        model: [
                            { key: "auto", label: "Auto" },
                            { key: "top", label: "Top" },
                            { key: "bottom", label: "Bot" }
                        ]

                        Rectangle {
                            required property var modelData
                            readonly property bool isCur: Config.notchAnchor === modelData.key

                            implicitWidth: 26
                            implicitHeight: 20
                            radius: 5
                            color: isCur ? Config.actBg : (segMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08))

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                font.family: Config.monoFont
                                font.pixelSize: 9
                                font.weight: parent.isCur ? Font.Bold : Font.Normal
                                color: parent.isCur ? Config.actFg : Config.dimFg
                            }

                            MouseArea {
                                id: segMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.notchAnchor = parent.modelData.key;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
