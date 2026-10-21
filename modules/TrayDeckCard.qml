import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Config.subPillBg
        border.color: Config.subPillBorder
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: "No active tray applications"
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                visible: trayMod.implicitWidth === 0
            }

            TrayModule {
                id: trayMod
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
