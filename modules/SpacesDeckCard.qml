import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    // State bindings
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property string focusedMonName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    
    // Inspected workspace ID (clicking workspace pills previews its windows without moving focus)
    property int selectedWsId: activeWsId

    // Auto-sync selectedWsId if activeWsId changes externally, unless user explicitly selected one
    onActiveWsIdChanged: {
        selectedWsId = activeWsId;
    }

    // Scratchpad state
    property bool isScratchpadActive: false
    property var occupiedWsIds: []
    property var activeSpaceWindows: []

    function refreshSpacesData() {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();

        // Calculate occupied workspaces
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
        interval: 3000
        repeat: true
        running: Config.expanded && Config.galleryIndex === 1
        triggeredOnStart: true
        onTriggered: root.refreshSpacesData()
    }

    Component.onCompleted: {
        root.refreshSpacesData();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // =====================================================================
        // Row 1: Workspace Strip, Scratchpad, and Monitor Info
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 8

            // Workspaces Capsule Bar
            Rectangle {
                implicitHeight: 28
                implicitWidth: wsRow.implicitWidth + 12
                radius: 14
                color: Config.subPillBg
                border.color: Config.subPillBorder
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
                            readonly property bool isSelected: root.selectedWsId === modelData
                            readonly property bool isCurrentFocused: root.activeWsId === modelData
                            readonly property bool isOccupied: !!(root.occupiedWsIds && root.occupiedWsIds[modelData])
                            
                            // Visual properties
                            implicitWidth: isSelected ? 28 : (isOccupied ? 24 : 20)
                            implicitHeight: 20
                            radius: 10

                            scale: wsMouse.pressed ? 0.90 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 100 }
                            }

                            color: isSelected ? Config.actBg : (wsMouse.containsMouse ? Config.hvrBg : "transparent")
                            border.color: isSelected ? "transparent" : (isCurrentFocused ? Qt.rgba(1, 1, 1, 0.3) : (isOccupied ? Qt.rgba(1, 1, 1, 0.12) : "transparent"))
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: wsPill.modelData.toString()
                                    color: wsPill.isSelected ? Config.actFg : (wsMouse.containsMouse ? Config.hvrFg : (wsPill.isOccupied ? Config.mainFg : Qt.rgba(1, 1, 1, 0.35)))
                                    font.family: Config.monoFont
                                    font.pixelSize: 11
                                    font.weight: wsPill.isSelected ? Font.Bold : Font.Normal
                                }

                                // Occupancy dot
                                Rectangle {
                                    visible: !wsPill.isSelected && wsPill.isOccupied
                                    implicitWidth: 3
                                    implicitHeight: 3
                                    radius: 1.5
                                    color: wsPill.isCurrentFocused ? Config.actFg : Qt.rgba(1, 1, 1, 0.5)
                                }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Switch inspected workspace in the deck without moving desktop focus
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
                implicitHeight: 28
                implicitWidth: scratchRow.implicitWidth + 14
                radius: 14
                color: (root.occupiedWsIds && root.occupiedWsIds[-99]) ? Qt.rgba(0.9, 0.6, 0.2, 0.18) : Config.subPillBg
                border.color: (root.occupiedWsIds && root.occupiedWsIds[-99]) ? Qt.rgba(0.9, 0.6, 0.2, 0.35) : Config.subPillBorder
                border.width: 1

                RowLayout {
                    id: scratchRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "󰊠"
                        font.family: Config.iconFont
                        font.pixelSize: 12
                        color: (root.occupiedWsIds && root.occupiedWsIds[-99]) ? "#f39c12" : Config.mainFg
                    }

                    Text {
                        text: "Scratchpad"
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: (root.occupiedWsIds && root.occupiedWsIds[-99]) ? "#f39c12" : Config.mainFg
                    }
                }

                MouseArea {
                    id: scratchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HyprlandLua.toggleSpecialWorkspace()
                }
            }

            Item { Layout.fillWidth: true }

            // Monitor & Window Stats
            Rectangle {
                implicitHeight: 24
                implicitWidth: monRow.implicitWidth + 12
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.05)

                RowLayout {
                    id: monRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰍹"
                        font.family: Config.iconFont
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }

                    Text {
                        text: (root.focusedMonName !== "" ? root.focusedMonName : "Monitor") + " • " + root.activeSpaceWindows.length + " win"
                        font.family: Config.bodyFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Qt.rgba(1, 1, 1, 0.75)
                    }
                }
            }
        }

        // =====================================================================
        // Row 2: Windows on Active Workspace (Mission Control Deck)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Config.subPillBg
            border.color: Config.subPillBorder
            border.width: 1
            clip: true

            // When windows exist in space
            Flickable {
                anchors.fill: parent
                anchors.margins: 6
                contentWidth: winRow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                RowLayout {
                    id: winRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Empty state prompt
                    Item {
                        visible: root.activeSpaceWindows.length === 0
                        implicitWidth: emptyRow.implicitWidth
                        implicitHeight: 34

                        RowLayout {
                            id: emptyRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "No active windows in Space " + root.selectedWsId
                                font.family: Config.bodyFont
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.4)
                            }

                            Rectangle {
                                implicitWidth: launchText.implicitWidth + 12
                                implicitHeight: 22
                                radius: 11
                                color: Qt.rgba(1, 1, 1, 0.08)

                                Text {
                                    id: launchText
                                    anchors.centerIn: parent
                                    text: "+ Launch App"
                                    font.family: Config.bodyFont
                                    font.pixelSize: 10
                                    color: Config.actFg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: HyprlandLua.launchApp()
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.activeSpaceWindows

                        Rectangle {
                            id: winCard
                            required property var modelData
                            
                            readonly property string appClass: (modelData.lastIpcObject && modelData.lastIpcObject.class) ? modelData.lastIpcObject.class : ""
                            readonly property string winTitle: modelData.title || appClass || "Window"
                            readonly property string winAddress: (modelData.lastIpcObject && modelData.lastIpcObject.address) ? modelData.lastIpcObject.address : ""
                            readonly property bool isWinActive: modelData.activated

                            implicitWidth: 150
                            implicitHeight: 38
                            radius: 9

                            color: isWinActive ? Qt.rgba(1, 1, 1, 0.14) : (winCardHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                            border.color: isWinActive ? Config.actBg : (winCardHover.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent")
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                IconImage {
                                    source: winCard.appClass !== "" ? Quickshell.iconPath(winCard.appClass.toLowerCase()) : ""
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: winCard.appClass !== "" ? winCard.appClass : "App"
                                        font.family: Config.bodyFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: winCard.isWinActive ? Config.actFg : Config.mainFg
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: winCard.winTitle
                                        font.family: Config.bodyFont
                                        font.pixelSize: 9
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: winCardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (winCard.winAddress !== "") {
                                        HyprlandLua.focusWindow(winCard.winAddress);
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
