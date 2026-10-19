import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: mainRow.implicitWidth
    implicitHeight: mainRow.implicitHeight

    property bool sunsetActive: false
    // States: "closed", "menu", "confirm_shutdown", "confirm_reboot", "confirm_logout"
    property string powerState: "closed"

    Timer {
        id: autoCloseTimer
        interval: 10000
        onTriggered: {
            root.powerState = "closed";
        }
    }

    onPowerStateChanged: {
        if (powerState !== "closed") {
            autoCloseTimer.restart();
        } else {
            autoCloseTimer.stop();
        }
    }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: 4

        // 1. DEFAULT VIEW (Night light & Power button)
        RowLayout {
            visible: root.powerState === "closed"
            spacing: 4

            // Night Light / Hyprsunset toggle
            IslandButton {
                icon: "󰖔"
                tooltip: "Night Light (hyprsunset toggle)"
                active: root.sunsetActive
                onClicked: {
                    HyprlandLua.toggleSunset();
                    root.sunsetActive = !root.sunsetActive;
                }
            }

            // Power Menu trigger button
            IslandButton {
                icon: ""
                tooltip: "Power: Lock, Sleep, Reboot, Shutdown (Right-click: wlogout)"
                textColor: Config.danger
                hoverBgColor: Config.danger
                onClicked: {
                    root.powerState = "menu";
                }
                onRightClicked: {
                    Config.run("wlogout || hyde-shell logoutlaunch 1");
                }
            }
        }

        // 2. SELECTION MENU VIEW
        RowLayout {
            visible: root.powerState === "menu"
            spacing: 3

            // Lock Screen
            IslandButton {
                icon: "󰌾"
                text: "Lock"
                tooltip: "Lock Screen (hyprlock)"
                onClicked: {
                    root.powerState = "closed";
                    HyprlandLua.lock();
                }
            }

            // Sleep / Suspend
            IslandButton {
                icon: "󰒲"
                text: "Sleep"
                tooltip: "Suspend System"
                onClicked: {
                    root.powerState = "closed";
                    Config.run("systemctl suspend");
                }
            }

            // Logout prompt
            IslandButton {
                icon: "󰗽"
                text: "Logout"
                tooltip: "Exit Hyprland Session"
                onClicked: {
                    root.powerState = "confirm_logout";
                }
            }

            // Reboot prompt
            IslandButton {
                icon: "󰜉"
                text: "Reboot"
                tooltip: "Reboot System"
                textColor: Config.warning
                hoverBgColor: Config.warning
                onClicked: {
                    root.powerState = "confirm_reboot";
                }
            }

            // Shutdown prompt
            IslandButton {
                icon: ""
                text: "Off"
                tooltip: "Power Off System"
                textColor: Config.danger
                hoverBgColor: Config.danger
                onClicked: {
                    root.powerState = "confirm_shutdown";
                }
            }

            // Cancel button
            IslandButton {
                icon: "󰅖"
                tooltip: "Cancel"
                onClicked: {
                    root.powerState = "closed";
                }
            }
        }

        // 3. SHUTDOWN CONFIRMATION VIEW
        RowLayout {
            visible: root.powerState === "confirm_shutdown"
            spacing: 4

            Text {
                text: "Shutdown?"
                color: Config.danger
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            IslandButton {
                icon: ""
                text: "Confirm"
                textColor: Config.danger
                hoverBgColor: Config.danger
                tooltip: "Confirm system power off"
                onClicked: {
                    root.powerState = "closed";
                    HyprlandLua.poweroff();
                }
            }

            IslandButton {
                icon: "󰅖"
                text: "Cancel"
                tooltip: "Cancel"
                onClicked: {
                    root.powerState = "menu";
                }
            }
        }

        // 4. REBOOT CONFIRMATION VIEW
        RowLayout {
            visible: root.powerState === "confirm_reboot"
            spacing: 4

            Text {
                text: "Reboot?"
                color: Config.warning
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            IslandButton {
                icon: "󰜉"
                text: "Confirm"
                textColor: Config.warning
                hoverBgColor: Config.warning
                tooltip: "Confirm system reboot"
                onClicked: {
                    root.powerState = "closed";
                    HyprlandLua.reboot();
                }
            }

            IslandButton {
                icon: "󰅖"
                text: "Cancel"
                tooltip: "Cancel"
                onClicked: {
                    root.powerState = "menu";
                }
            }
        }

        // 5. LOGOUT CONFIRMATION VIEW
        RowLayout {
            visible: root.powerState === "confirm_logout"
            spacing: 4

            Text {
                text: "Logout?"
                color: Config.mainFg
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            IslandButton {
                icon: "󰗽"
                text: "Confirm"
                textColor: Config.actFg
                hoverBgColor: Config.actBg
                tooltip: "Confirm logout from Hyprland"
                onClicked: {
                    root.powerState = "closed";
                    HyprlandLua.exit();
                }
            }

            IslandButton {
                icon: "󰅖"
                text: "Cancel"
                tooltip: "Cancel"
                onClicked: {
                    root.powerState = "menu";
                }
            }
        }
    }
}
