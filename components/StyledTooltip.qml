import QtQuick
import ".."

Rectangle {
    id: root
    property string text: ""
    visible: false
    
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 8
    radius: 7
    color: Qt.rgba(0.08, 0.08, 0.10, 0.94)
    border.color: Qt.rgba(1, 1, 1, 0.14)
    border.width: 1
    z: 9999

    // Fluid Apple enter/exit transition
    opacity: root.visible ? 1.0 : 0.0
    scale: root.visible ? 1.0 : 0.88
    transformOrigin: Config.activeAnchorEdge === "bottom" ? Item.Bottom : Item.Top

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutBack
            easing.overshoot: 1.12
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Config.mainFg
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        font.weight: Font.Medium
        textFormat: Text.PlainText
    }
}
