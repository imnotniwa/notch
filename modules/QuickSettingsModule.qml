import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property bool sunsetActive: false
    property bool caffeineActive: false

    RowLayout {
        id: row
        anchors.fill: parent
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

        // Lock Screen
        IslandButton {
            icon: "󰌾"
            tooltip: "Lock Screen (hyprlock)"
            onClicked: {
                HyprlandLua.lock();
            }
        }

        // Logout
        IslandButton {
            icon: "󰗽"
            tooltip: "Exit Hyprland"
            onClicked: {
                HyprlandLua.exit();
            }
        }

        // Power Off
        IslandButton {
            icon: ""
            tooltip: "Power Off (systemctl poweroff)"
            textColor: Config.danger
            hoverBgColor: Config.danger
            onClicked: {
                HyprlandLua.poweroff();
            }
        }
    }
}
