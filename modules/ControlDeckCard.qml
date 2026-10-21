import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: 520
    implicitHeight: 96

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Left Section: Audio Volume & Display Backlight
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Volume Card (Audio sink & pavucontrol)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Config.subPillBg
                border.color: Config.subPillBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    AudioModule {
                        compactMode: false
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Display Brightness Card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Config.subPillBg
                border.color: Config.subPillBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    BacklightModule {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Right Section: Network & Quick System Toggles
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Wi-Fi Network Card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Config.subPillBg
                border.color: Config.subPillBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    NetworkModule {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // System Updates & Quick Toggles Card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Config.subPillBg
                border.color: Config.subPillBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    UpdatesModule {
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        visible: updatesModCheck.visible
                        width: 1
                        height: 16
                        color: Qt.rgba(1, 1, 1, 0.12)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    QuickSettingsModule {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

    UpdatesModule {
        id: updatesModCheck
        visible: false
    }
}
