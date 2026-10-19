import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Track active workspace
    property int activeWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // Track active toplevel window
    property string activeTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
    property string activeClass: (Hyprland.activeToplevel && Hyprland.activeToplevel.lastIpcObject) ? (Hyprland.activeToplevel.lastIpcObject.class || "") : ""

    // Clock
    property string timeStr: ""
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.timeStr = Qt.formatTime(new Date(), "hh:mm");
        }
    }

    // Audio status
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volumePct: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property string volumeIcon: isMuted ? "󰖁" : (volumePct > 50 ? "" : "")

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 12

        // Left Section: Active Workspace + Time
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                implicitWidth: 22
                implicitHeight: 20
                radius: 10
                color: Config.actBg
                Text {
                    anchors.centerIn: parent
                    text: root.activeWorkspaceId.toString()
                    color: Config.actFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: true
                }
            }

            Text {
                text: root.timeStr
                color: Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.bold: true
            }
        }

        // Center Section: Active App Icon + Truncated Window Title
        RowLayout {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 160
            clip: true

            IconImage {
                visible: root.activeClass !== ""
                source: root.activeClass !== "" ? Quickshell.iconPath(root.activeClass.toLowerCase()) : ""
                implicitWidth: 14
                implicitHeight: 14
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.activeTitle !== "" ? root.activeTitle : "Hyprland"
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                elide: Text.ElideRight
                Layout.maximumWidth: 140
            }
        }

        // Right Section: Audio + Battery status
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            // Battery indicator (shows percentage if on battery / not charging)
            BatteryModule {
                compactMode: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Volume indicator
            RowLayout {
                spacing: 3
                Text {
                    text: root.volumeIcon
                    color: root.isMuted ? Config.danger : Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.iconSize
                }
                Text {
                    text: root.volumePct + "%"
                    color: Config.mainFg
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }
            }

            // Minimal expand indicator
            Text {
                text: "󰅂"
                color: Config.dimFg
                font.family: Config.fontFamily
                font.pixelSize: 12
            }
        }
    }
}
