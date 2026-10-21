import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    RowLayout {
        anchors.fill: parent
        spacing: 14

        // System Monitor Performance card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 14
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                SysMonModule {
                    compactMode: false
                }
            }
        }

        // Battery Glance Card
        Rectangle {
            implicitWidth: 160
            implicitHeight: 52
            radius: 14
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                BatteryModule {
                    compactMode: false
                }
            }
        }
    }
}
