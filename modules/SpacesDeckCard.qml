import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 600
    implicitHeight: 228

    // State bindings
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property string focusedMonName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    // Currently inspected workspace ID
    property int selectedWsId: activeWsId

    onActiveWsIdChanged: {
        selectedWsId = activeWsId;
    }

    property var occupiedWsIds: ({})
    property var activeSpaceWindows: []

    function refreshSpacesData() {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();

        let occupied = {};
        let currentWins = [];
        let viewWs = root.selectedWsId;

        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            let toplevelList = Hyprland.toplevels.values;
            for (let i = 0; i < toplevelList.length; i++) {
                let win = toplevelList[i];
                let wsId = win.workspace ? win.workspace.id : (win.lastIpcObject && win.lastIpcObject.workspace ? win.lastIpcObject.workspace.id : null);
                if (wsId !== null && wsId !== undefined) {
                    occupied[wsId] = (occupied[wsId] || 0) + 1;
                    if (wsId === viewWs) {
                        currentWins.push(win);
                    }
                }
            }
        }
        root.occupiedWsIds = occupied;
        root.activeSpaceWindows = currentWins;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "focusedmon" || 
                event.name === "createworkspace" || event.name === "destroyworkspace" ||
                event.name === "openwindow" || event.name === "closewindow" ||
                event.name === "movewindow" || event.name === "activewindow" ||
                event.name === "windowtitle" || event.name === "fullscreen") {
                root.refreshSpacesData();
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: Config.expanded && Config.galleryIndex === 2
        triggeredOnStart: true
        onTriggered: root.refreshSpacesData()
    }

    Component.onCompleted: {
        root.refreshSpacesData();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // =====================================================================
        // Top Navigation Strip: Workspace Pills & Scratchpad
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 10

            // Workspaces Capsule Bar
            Rectangle {
                implicitHeight: 32
                implicitWidth: wsRow.implicitWidth + 12
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: [1, 2, 3, 4, 5, 6, 7]

                        Rectangle {
                            id: wsPill
                            required property int modelData
                            readonly property bool isInspected: root.selectedWsId === modelData
                            readonly property bool isCurrentDesktop: root.activeWsId === modelData
                            readonly property bool isOccupied: !!(root.occupiedWsIds && root.occupiedWsIds[modelData])

                            implicitWidth: isInspected ? 36 : (isOccupied ? 28 : 24)
                            implicitHeight: 24
                            radius: 12

                            color: isInspected ? Config.actBg : (wsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                            border.color: isInspected ? "transparent" : (isCurrentDesktop ? Qt.rgba(1, 1, 1, 0.35) : "transparent")
                            border.width: 1

                            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: wsPill.modelData.toString()
                                    color: wsPill.isInspected ? "#ffffff" : (wsPill.isOccupied ? Config.mainFg : Qt.rgba(1, 1, 1, 0.35))
                                    font.family: Config.bodyFont
                                    font.pixelSize: 11
                                    font.weight: wsPill.isInspected || wsPill.isCurrentDesktop ? Font.Bold : Font.Normal
                                }

                                // Occupancy indicator dot
                                Rectangle {
                                    visible: !wsPill.isInspected && wsPill.isOccupied
                                    width: 3
                                    height: 3
                                    radius: 1.5
                                    color: wsPill.isCurrentDesktop ? Config.actBg : Qt.rgba(1, 1, 1, 0.6)
                                }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedWsId = wsPill.modelData;
                                    root.refreshSpacesData();
                                }
                            }
                        }
                    }
                }
            }

            // Scratchpad Toggle Capsule
            Rectangle {
                implicitHeight: 32
                implicitWidth: scratchRow.implicitWidth + 16
                radius: 16
                readonly property bool hasScratch: !!(root.occupiedWsIds && root.occupiedWsIds[-99])
                color: hasScratch ? Qt.rgba(1, 0.62, 0.04, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                border.color: hasScratch ? Qt.rgba(1, 0.62, 0.04, 0.4) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    id: scratchRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰊠"
                        font.family: Config.iconFont
                        font.pixelSize: 13
                        color: parent.parent.hasScratch ? "#ff9f0a" : Config.mainFg
                    }

                    Text {
                        text: "Scratchpad" + (parent.parent.hasScratch ? " (" + root.occupiedWsIds[-99] + ")" : "")
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: parent.parent.hasScratch ? "#ff9f0a" : Config.mainFg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedWsId = -99;
                        root.refreshSpacesData();
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Switch Whole Desktop to Selected Space Button
            Rectangle {
                implicitHeight: 28
                implicitWidth: switchText.implicitWidth + 18
                radius: 14
                visible: root.selectedWsId !== root.activeWsId && root.selectedWsId !== -99
                color: switchM.pressed ? Qt.darker(Config.actBg, 1.2) : (switchM.containsMouse ? Qt.lighter(Config.actBg, 1.1) : Config.actBg)

                Text {
                    id: switchText
                    anchors.centerIn: parent
                    text: "Jump to Space " + root.selectedWsId + " ↗"
                    color: "#ffffff"
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: switchM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.run("hyprctl dispatch workspace " + root.selectedWsId);
                    }
                }
            }
        }

        // =====================================================================
        // Main Area: Mission Control Interactive Window Cards Grid
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.03)
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            clip: true

            // Empty state if no windows in this workspace
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.activeSpaceWindows.length === 0

                Text {
                    text: "󰍺"
                    font.family: Config.iconFont
                    font.pixelSize: 32
                    color: Qt.rgba(1, 1, 1, 0.2)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No active windows in " + (root.selectedWsId === -99 ? "Scratchpad" : "Space " + root.selectedWsId)
                    font.family: Config.bodyFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.4)
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Grid of Window Cards (Mission Control Style)
            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: winGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: winGrid
                    width: parent.width
                    columns: Math.max(1, Math.min(3, root.activeSpaceWindows.length))
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.activeSpaceWindows

                        Rectangle {
                            id: card
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 82
                            radius: 12

                            readonly property string appClass: (modelData.lastIpcObject && modelData.lastIpcObject.class) ? modelData.lastIpcObject.class : ""
                            readonly property string winTitle: modelData.title || appClass || "Window"
                            readonly property string winAddress: (modelData.lastIpcObject && modelData.lastIpcObject.address) ? modelData.lastIpcObject.address : ""
                            readonly property bool isWinActive: modelData.activated

                            color: isWinActive ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.18) : (cardHover.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05))
                            border.color: isWinActive ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.45) : (cardHover.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.07))
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                // Header row: App Icon + App Class + Close Button
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    IconImage {
                                        source: card.appClass !== "" ? Quickshell.iconPath(card.appClass.toLowerCase()) : ""
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: card.appClass !== "" ? card.appClass : "Application"
                                        color: card.isWinActive ? "#ffffff" : Config.mainFg
                                        font.family: Config.bodyFont
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Window Title text (clean truncated)
                                Text {
                                    text: card.winTitle
                                    color: Config.dimFg
                                    font.family: Config.bodyFont
                                    font.pixelSize: 11
                                    font.weight: Font.Normal
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Status badge row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        implicitWidth: focusBadge.implicitWidth + 10
                                        implicitHeight: 16
                                        radius: 8
                                        color: card.isWinActive ? Qt.rgba(Config.actBg.r, Config.actBg.g, Config.actBg.b, 0.25) : Qt.rgba(1, 1, 1, 0.08)

                                        Text {
                                            id: focusBadge
                                            anchors.centerIn: parent
                                            text: card.isWinActive ? "Active" : "Focus ↗"
                                            color: card.isWinActive ? Config.actBg : Config.dimFg
                                            font.family: Config.bodyFont
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }
                            }

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (card.winAddress !== "") {
                                        HyprlandLua.focusWindow(card.winAddress);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
