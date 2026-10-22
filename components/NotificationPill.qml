import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import "../core"

Item {
    id: root

    readonly property var notif: Config.activeNotification
    readonly property bool isCritical: notif && notif.urgency === 2

    implicitHeight: 56
    implicitWidth: contentRow.implicitWidth

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: 14

        // =====================================================================
        // AVATAR / APP BADGE (Circular avatar with small app badge overlap)
        // =====================================================================
        Item {
            implicitWidth: 44
            implicitHeight: 44
            Layout.alignment: Qt.AlignVCenter

            // Main circular avatar or large app icon
            Rectangle {
                id: avatarBg
                width: 42
                height: 42
                radius: 21
                color: root.isCritical ? Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.25) : Qt.rgba(1, 1, 1, 0.12)
                border.color: root.isCritical ? Config.danger : Qt.rgba(1, 1, 1, 0.16)
                border.width: 1
                anchors.left: parent.left
                anchors.top: parent.top

                IconImage {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    source: (root.notif && root.notif.appIcon) ? Quickshell.iconPath(root.notif.appIcon) : ""
                    visible: source != ""
                }

                Text {
                    anchors.centerIn: parent
                    text: root.isCritical ? "󰀦" : (root.notif && root.notif.summary ? root.notif.summary.charAt(0).toUpperCase() : (root.notif && root.notif.appName ? root.notif.appName.charAt(0).toUpperCase() : "󰂚"))
                    font.family: (root.isCritical || !(root.notif && (root.notif.summary || root.notif.appName))) ? Config.iconFont : Config.bodyFont
                    font.pixelSize: (root.isCritical || !(root.notif && (root.notif.summary || root.notif.appName))) ? 18 : 16
                    font.weight: Font.Bold
                    color: root.isCritical ? Config.danger : Config.mainFg
                    visible: !(root.notif && root.notif.appIcon) || !parent.children[0].visible
                }
            }

            // Small bottom-right app badge (e.g., WhatsApp, Teams, Discord, System)
            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: root.isCritical ? Config.danger : (root.notif && root.notif.badgeColor ? root.notif.badgeColor : Config.actBg)
                border.color: "#000000"
                border.width: 1.5
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                IconImage {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    source: (root.notif && root.notif.appIcon) ? Quickshell.iconPath(root.notif.appIcon) : ""
                    visible: source != ""
                }

                Text {
                    anchors.centerIn: parent
                    text: root.notif && root.notif.badgeIcon ? root.notif.badgeIcon : "󰂚"
                    font.family: Config.iconFont
                    font.pixelSize: 9
                    color: "#ffffff"
                    visible: !(root.notif && root.notif.appIcon) || !parent.children[0].visible
                }
            }
        }

        // =====================================================================
        // TEXT CONTENT (Sender / Summary, 2-line message body, and 'now' timestamp)
        // =====================================================================
        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(Math.max(bodyLine1.implicitWidth, titleRow.implicitWidth), 310)

            // Top Row: Sender / Summary Title, App Name tag, and "now" timestamp
            RowLayout {
                id: titleRow
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.notif ? root.notif.summary : ""
                    font.family: Config.bodyFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.isCritical ? Config.danger : Config.mainFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Clean App Name Badge if different from Sender
                Rectangle {
                    implicitHeight: 16
                    implicitWidth: appTagText.implicitWidth + 8
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.08)
                    visible: root.notif && root.notif.appName && root.notif.appName !== root.notif.summary
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: appTagText
                        anchors.centerIn: parent
                        text: root.notif ? root.notif.appName : ""
                        font.family: Config.bodyFont
                        font.pixelSize: 9
                        color: Config.dimFg
                        font.weight: Font.Medium
                    }
                }

                Text {
                    text: "now"
                    font.family: Config.bodyFont
                    font.pixelSize: 11
                    color: Config.dimFg
                    font.weight: Font.Normal
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }

            // Message Body: Multi-line layout like Apple Dynamic Island message preview
            Text {
                id: bodyLine1
                text: root.notif ? root.notif.body : ""
                font.family: Config.bodyFont
                font.pixelSize: 12
                color: Qt.rgba(1, 1, 1, 0.72)
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }

        // =====================================================================
        // ACTION BUTTONS (If provided by the notification)
        // =====================================================================
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            visible: root.notif && root.notif.actions && root.notif.actions.length > 0

            Repeater {
                model: (root.notif && root.notif.actions) ? root.notif.actions : []
                delegate: Rectangle {
                    required property var modelData
                    implicitHeight: 24
                    implicitWidth: actText.implicitWidth + 16
                    radius: 12
                    color: actMouse.pressed ? Qt.rgba(1, 1, 1, 0.28) : (actMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10))
                    border.color: Qt.rgba(1, 1, 1, 0.14)
                    border.width: 1

                    Text {
                        id: actText
                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier
                        font.family: Config.bodyFont
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Config.mainFg
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.invokeAction(root.notif, modelData);
                        }
                    }
                }
            }
        }

        // =====================================================================
        // CLOSE / DISMISS "✕" BUTTON
        // =====================================================================
        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: closeMouse.pressed ? Qt.rgba(1, 1, 1, 0.25) : (closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.06))
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.family: Config.bodyFont
                font.pixelSize: 10
                color: Config.dimFg
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    NotificationService.dismissActive();
                }
            }
        }
    }
}
