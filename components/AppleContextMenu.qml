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
            root.activeSubMenu = null;
        }
    }

    QsMenuOpener {
        id: opener
        menu: Config.trayActiveMenu
    }

    // Active sub-item opener for cascading menus (such as Wi-Fi network lists)
    property var activeSubMenu: null
    property real subMenuY: 0
    property real subMenuX: 0
    property bool isSubMenuLoading: false

    function openSubMenu(entry, targetItem) {
        if (!entry) return;
        let pt = targetItem.mapToItem(null, 0, 0);
        root.subMenuX = menuCard.x + menuCard.width + 6;
        root.subMenuY = pt.y;
        root.activeSubMenu = entry;
        root.isSubMenuLoading = true;

        if (typeof entry.sendOpened === "function") {
            entry.sendOpened();
        }
        if (typeof entry.updateLayout === "function") {
            entry.updateLayout();
        }
        subLoadTimeout.restart();
    }

    Timer {
        id: subLoadTimeout
        interval: 1500
        onTriggered: {
            root.isSubMenuLoading = false;
        }
    }

    QsMenuOpener {
        id: subOpener
        menu: root.activeSubMenu
        onChildrenChanged: {
            if (children && (children.count > 0 || (children.values && children.values.length > 0))) {
                root.isSubMenuLoading = false;
                subLoadTimeout.stop();
            }
        }
    }

    Rectangle {
        id: menuCard
        readonly property bool isBottom: Config.activeAnchorEdge === "bottom"
        readonly property real screenH: screen ? screen.height : 1080
        readonly property real screenW: screen ? screen.width : 1920

        x: Math.max(16, Math.min(Config.trayMenuX, screenW - width - 16))
        // Position upward above bottom notch or downward below top notch
        y: isBottom ? (screenH - Config.expandedHeight - height - 12) : (Config.expandedHeight + 8)
        width: Math.max(190, col.implicitWidth + 24)
        implicitHeight: col.implicitHeight + 14
        radius: 14

        // Apple spatial consistency: originate animation toward the trigger origin
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

        scale: Config.trayMenuVisible ? 1.0 : 0.94
        opacity: Config.trayMenuVisible ? 1.0 : 0.0

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

            Repeater {
                model: opener.children

                Rectangle {
                    id: itemContainer
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

                        // Submenu indicator arrow (e.g. for Wi-Fi Networks list)
                        Text {
                            visible: !!modelData.hasChildren
                            text: "›"
                            color: Config.dimFg
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.isSeparator && modelData.enabled
                        cursorShape: Qt.PointingHandCursor

                        onEntered: {
                            if (modelData.hasChildren) {
                                root.openSubMenu(modelData, itemContainer);
                            }
                        }

                        onClicked: {
                            if (modelData.hasChildren) {
                                root.openSubMenu(modelData, itemContainer);
                            } else {
                                modelData.triggered();
                                Config.trayMenuVisible = false;
                                root.activeSubMenu = null;
                            }
                        }
                    }
                }
            }
        }
    }

    // Cascading Sub-menu Card (for Wi-Fi network list & sub-items)
    Rectangle {
        id: subMenuCard
        readonly property real screenH: screen ? screen.height : 1080
        readonly property real screenW: screen ? screen.width : 1920
        readonly property bool hasChildItems: subOpener.children && (subOpener.children.count > 0 || (subOpener.children.values && subOpener.children.values.length > 0))

        visible: root.activeSubMenu !== null
        x: Math.min(root.subMenuX, screenW - width - 16)
        y: Math.max(16, Math.min(root.subMenuY, screenH - height - 16))
        width: Math.max(200, Math.max(subCol.implicitWidth + 24, loadingRow.implicitWidth + 24))
        implicitHeight: root.isSubMenuLoading && !hasChildItems 
            ? 44 
            : Math.max(40, subCol.implicitHeight + 14)
        radius: 14

        color: "#f018181b"
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        scale: visible ? 1.0 : 0.94
        opacity: visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.08 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Apple loading state indicator while DBus resolves child Wi-Fi networks
        RowLayout {
            id: loadingRow
            anchors.centerIn: parent
            spacing: 8
            visible: root.isSubMenuLoading && !subMenuCard.hasChildItems

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: "transparent"
                border.color: Config.actBg
                border.width: 2
                Layout.alignment: Qt.AlignVCenter

                RotationAnimation on rotation {
                    running: loadingRow.visible
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                }
            }

            Text {
                text: "Loading networks..."
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Empty state fallback when loaded with 0 children
        Text {
            anchors.centerIn: parent
            text: "No networks available"
            color: Config.dimFg
            font.family: Config.fontFamily
            font.pixelSize: 11
            visible: !root.isSubMenuLoading && !subMenuCard.hasChildItems
        }

        ColumnLayout {
            id: subCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 5
            spacing: 2
            visible: !loadingRow.visible && subMenuCard.hasChildItems

            Repeater {
                model: subOpener.children ? (subOpener.children.values || subOpener.children) : []

                Rectangle {
                    id: subItemContainer
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.isSeparator ? 1 : 28
                    radius: 7

                    color: modelData.isSeparator 
                        ? Qt.rgba(1, 1, 1, 0.1) 
                        : (subItemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")

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
                            color: modelData.enabled ? Config.mainFg : Config.dimFg
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: subItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.isSeparator && modelData.enabled
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            modelData.triggered();
                            Config.trayMenuVisible = false;
                            root.activeSubMenu = null;
                        }
                    }
                }
            }
        }
    }
}

