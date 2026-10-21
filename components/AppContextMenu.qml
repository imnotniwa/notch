import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../core"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    visible: Config.appMenuVisible

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Fullscreen transparent backdrop: catches outside clicks reliably
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Config.appMenuVisible = false;
            Config.activeAppWindow = null;
        }
    }

    Rectangle {
        id: menuCard
        readonly property bool isBottom: Config.activeAnchorEdge === "bottom"
        readonly property real screenH: screen ? screen.height : 1080
        readonly property real screenW: screen ? screen.width : 1920

        x: Math.max(16, Math.min(Config.appMenuX, screenW - width - 16))
        // Position upward above bottom notch or downward below top notch
        y: isBottom ? (screenH - Config.expandedHeight - height - 12) : (Config.expandedHeight + 8)
        width: Math.max(200, col.implicitWidth + 24)
        implicitHeight: col.implicitHeight + 14
        radius: 14

        // Apple spatial consistency
        transformOrigin: isBottom ? Item.BottomLeft : Item.TopLeft

        // Prevent clicks on the menu card from triggering backdrop dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Apple Dark Translucent Acrylic Material
        color: "#f018181b"
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        scale: Config.appMenuVisible ? 1.0 : 0.94
        opacity: Config.appMenuVisible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutBack
                easing.overshoot: 1.08
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

            // Header: Application title
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                color: "transparent"
                visible: Config.activeAppWindow !== null

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    text: Config.activeAppWindow ? (Config.activeAppWindow.title || Config.activeAppWindow.appClass || "Application") : ""
                    color: Config.dimFg
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            // Action: Focus
            Rectangle {
                id: focusAction
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 7
                color: focusMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    Text {
                        text: "󰖲"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                    }

                    Text {
                        text: "Focus Window"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: focusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.activeAppWindow && Config.activeAppWindow.address) {
                            HyprlandLua.focusWindow(Config.activeAppWindow.address);
                        }
                        Config.appMenuVisible = false;
                        Config.activeAppWindow = null;
                    }
                }
            }

            // Action: Toggle Fullscreen
            Rectangle {
                id: fsAction
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 7
                color: fsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    Text {
                        text: "󰊓"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                    }

                    Text {
                        text: "Toggle Fullscreen"
                        color: Config.mainFg
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: fsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.activeAppWindow && Config.activeAppWindow.address) {
                            HyprlandLua.fullscreenWindow(Config.activeAppWindow.address);
                        }
                        Config.appMenuVisible = false;
                        Config.activeAppWindow = null;
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            // Action: Close Window (Destructive)
            Rectangle {
                id: closeAction
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 7
                color: closeMouse.containsMouse ? Qt.rgba(1, 0.27, 0.23, 0.2) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    Text {
                        text: "󰅖"
                        color: Config.danger
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                    }

                    Text {
                        text: "Close Window"
                        color: Config.danger
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.activeAppWindow && Config.activeAppWindow.address) {
                            HyprlandLua.closeWindow(Config.activeAppWindow.address);
                        }
                        Config.appMenuVisible = false;
                        Config.activeAppWindow = null;
                    }
                }
            }
        }
    }
}
