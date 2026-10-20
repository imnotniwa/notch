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

        // Lock Screen shortcut
        IslandButton {
            icon: "󰌾"
            tooltip: "Lock Screen (hyprlock)"
            onClicked: {
                HyprlandLua.lock();
            }
        }

        // Power Modal Trigger Button
        IslandButton {
            icon: ""
            tooltip: "Power Menu: Lock, Sleep, Logout, Reboot, Shutdown"
            textColor: Config.danger
            hoverBgColor: Qt.rgba(Config.danger.r, Config.danger.g, Config.danger.b, 0.16)
            onClicked: {
                Config.powerModalVisible = true;
            }
            onRightClicked: {
                Config.run("wlogout || hyde-shell logoutlaunch 1");
            }
        }
    }
}
