import QtQuick
import ".."

Rectangle {
    id: root
    property string text: ""
    visible: text !== ""
    
    width: label.implicitWidth + 14
    height: label.implicitHeight + 8
    radius: 6
    color: Config.islandBg
    border.color: Config.islandBorder
    border.width: 1
    z: 9999

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Config.mainFg
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        textFormat: Text.PlainText
    }
}
