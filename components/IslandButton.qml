import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    
    property string text: ""
    property string icon: ""
    property string tooltip: ""
    property bool active: false
    property bool isMonoFont: false
    property color textColor: active ? Config.actFg : (mouseArea.containsMouse ? Config.hvrFg : Config.mainFg)
    property color hoverBgColor: Qt.rgba(1, 1, 1, 0.12)
    property color activeBgColor: Config.actBg
    property int customPaddingH: 8
    property int customPaddingV: 4

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolledUp()
    signal scrolledDown()

    implicitWidth: contentRow.implicitWidth + (customPaddingH * 2)
    implicitHeight: Math.max(contentRow.implicitHeight + (customPaddingV * 2), 26)
    radius: 9

    // Apple tactile feedback: scale down on press, spring back on release
    scale: mouseArea.pressed ? 0.92 : 1.0
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: mouseArea.pressed ? 60 : 180
            easing.type: mouseArea.pressed ? Easing.OutQuad : Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    // Apple subtle translucent material highlight
    color: active ? activeBgColor : (mouseArea.pressed ? Qt.rgba(1, 1, 1, 0.18) : (mouseArea.containsMouse ? hoverBgColor : "transparent"))

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.textColor
            font.family: Config.fontFamily
            font.pixelSize: Config.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: root.textColor
            font.family: root.isMonoFont ? Config.monoFontFamily : Config.fontFamily
            font.pixelSize: Config.fontSize
            font.weight: root.active ? Font.DemiBold : Font.Normal
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.clicked();
            } else if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else if (mouse.button === Qt.MiddleButton) {
                root.middleClicked();
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                root.scrolledUp();
            } else if (wheel.angleDelta.y < 0) {
                root.scrolledDown();
            }
        }
    }

    // Tooltip display on hover
    StyledTooltip {
        id: tip
        text: root.tooltip
        visible: mouseArea.containsMouse && root.tooltip !== ""
        anchors.top: root.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: root.horizontalCenter
    }
}
