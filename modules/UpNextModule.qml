import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    implicitWidth: 260
    implicitHeight: 220

    property var events: [
        {
            title: "Design review",
            time: "3:00 PM · Studio 2",
            color: "#af52de" // Purple accent
        },
        {
            title: "Gym",
            time: "5:30 PM · 45 min",
            color: "#34c759" // Green accent
        },
        {
            title: "Team Sync",
            time: "7:00 PM · Google Meet",
            color: "#0071e3" // Blue accent
        },
        {
            title: "Focus Time",
            time: "9:00 PM · Deep Work",
            color: "#ff9f0a" // Orange accent
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header: UP NEXT
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

            Item { Layout.fillWidth: true }
        }

        // Agenda Items List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 12
            model: root.events

            delegate: RowLayout {
                required property var modelData
                width: ListView.view.width
                spacing: 10

                // Vertical accent bar
                Rectangle {
                    implicitWidth: 3.5
                    implicitHeight: 34
                    radius: 2
                    color: modelData.color || Config.actBg
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: modelData.title
                        color: Config.mainFg
                        font.family: Config.bodyFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.time
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
