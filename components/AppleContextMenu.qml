import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    visible: Config.trayMenuVisible

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Fullscreen transparent backdrop: catches outside clicks reliably without focus-stealing or re-triggering hover animations
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Config.trayMenuVisible = false;
        }
    }

    QsMenuOpener {
        id: opener
        menu: Config.trayActiveMenu
    }

    Rectangle {
        id: menuCard
        x: Math.max(16, Math.min(Config.trayMenuX, (screen ? screen.width : 1920) - width - 16))
        y: Config.trayMenuY
        width: Math.max(190, col.implicitWidth + 24)
        implicitHeight: col.implicitHeight + 14
        radius: 14

        // Prevent clicks on the menu card from triggering backdrop dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Apple Dark Translucent Acrylic Material
        color: "#f018181b"
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        scale: Config.trayMenuVisible ? 1.0 : 0.94
        opacity: Config.trayMenuVisible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: col
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 5
            spacing: 2

            Repeater {
                model: opener.children

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 1 : 28
                    radius: 7

                    readonly property bool isDestructive: {
                        let txt = (modelData.text || "").toLowerCase();
                        return txt.indexOf("quit") !== -1 || txt.indexOf("exit") !== -1;
                    }

                    color: modelData.isSeparator 
                        ? Qt.rgba(1, 1, 1, 0.1) 
                        : (itemMouse.containsMouse 
                            ? (isDestructive ? Qt.rgba(1, 0.27, 0.23, 0.2) : Qt.rgba(1, 1, 1, 0.12)) 
                            : "transparent")

                    // Separator divider
                    Rectangle {
                        anchors.fill: parent
                        visible: modelData.isSeparator
                        color: Qt.rgba(1, 1, 1, 0.1)
                        height: 1
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 8
                        visible: !modelData.isSeparator

                        Text {
                            text: modelData.text || ""
                            color: isDestructive 
                                ? Config.danger 
                                : (modelData.enabled ? Config.mainFg : Config.dimFg)
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: isDestructive ? Font.Medium : Font.Normal
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.isSeparator && modelData.enabled
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            modelData.triggered();
                            Config.trayMenuVisible = false;
                        }
                    }
                }
            }
        }
    }
}

