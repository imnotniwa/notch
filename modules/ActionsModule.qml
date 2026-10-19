import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../components"
import ".."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        // Keybind Hint
        IslandButton {
            icon: ""
            tooltip: "Keybinds Hint"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell keybinds_hint");
            }
        }

        // Wallpaper Switcher
        IslandButton {
            icon: "󰋩"
            tooltip: "Wallpaper (Left: Next, Right: Prev, Middle: Select)"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell app -t scope -- wallpaper.sh --next --global");
            }
            onRightClicked: {
                Hyprland.dispatch("exec hyde-shell app -t scope -- wallpaper.sh --previous --global");
            }
            onMiddleClicked: {
                Hyprland.dispatch("exec hyde-shell app -t scope -- wallpaper.sh --select --global");
            }
        }

        // Theme Switcher
        IslandButton {
            icon: ""
            tooltip: "Theme Switcher (Left: Next, Right: Prev, Middle: Select)"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell app -t scope -- theme.switch.sh -n");
            }
            onRightClicked: {
                Hyprland.dispatch("exec hyde-shell app -t scope -- theme.switch.sh -p");
            }
            onMiddleClicked: {
                Hyprland.dispatch("exec sleep 0.1 && hyde-shell app -t scope -- theme.select.sh");
            }
        }

        // Bar / Dock Switcher
        IslandButton {
            icon: ""
            tooltip: "Bar / Dock (Left: Next, Right: Prev, Middle: Quickapps)"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell waybar -n");
            }
            onRightClicked: {
                Hyprland.dispatch("exec hyde-shell waybar -p");
            }
            onMiddleClicked: {
                Hyprland.dispatch("exec hyde-shell quickapps");
            }
        }

        // Clipboard History
        IslandButton {
            icon: ""
            tooltip: "Clipboard History"
            onClicked: {
                Hyprland.dispatch("exec sleep 0.1 && hyde-shell cliphist -c");
            }
        }

        // HyDE Menu
        IslandButton {
            icon: ""
            tooltip: "HyDE Menu"
            onClicked: {
                Hyprland.dispatch("exec hyde-shell logoutlaunch 1");
            }
        }

        // Power Menu
        IslandButton {
            icon: ""
            tooltip: "Logout / Power Menu"
            textColor: Config.danger
            hoverBgColor: Config.danger
            onClicked: {
                Hyprland.dispatch("exec hyde-shell logoutlaunch 1");
            }
        }
    }
}
