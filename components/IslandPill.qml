import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int paddingHorizontal: 8
    property int paddingVertical: 4

    implicitWidth: row.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: row.implicitHeight + (paddingVertical * 2)

    radius: Config.innerPillRadius
    color: Config.subPillBg
    border.color: Config.subPillBorder
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
