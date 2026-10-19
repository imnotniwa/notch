import QtQuick
import QtQuick.Layouts
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
                Config.run("hyde-shell keybinds_hint");
            }
        }

        // Wallpaper Switcher
        IslandButton {
            icon: "󰋩"
            tooltip: "Wallpaper (Left: Next, Right: Prev, Middle: Select)"
            onClicked: {
                Config.run("hyde-shell app -t scope -- wallpaper.sh --next --global");
            }
            onRightClicked: {
                Config.run("hyde-shell app -t scope -- wallpaper.sh --previous --global");
            }
            onMiddleClicked: {
                Config.run("hyde-shell app -t scope -- wallpaper.sh --select --global");
            }
        }

        // Theme Switcher
        IslandButton {
            icon: ""
            tooltip: "Theme Switcher (Left: Next, Right: Prev, Middle: Select)"
            onClicked: {
                Config.run("hyde-shell app -t scope -- theme.switch.sh -n");
            }
            onRightClicked: {
                Config.run("hyde-shell app -t scope -- theme.switch.sh -p");
            }
            onMiddleClicked: {
                Config.run("sleep 0.1 && hyde-shell app -t scope -- theme.select.sh");
            }
        }

        // Bar / Dock Switcher
        IslandButton {
            icon: ""
            tooltip: "Bar / Dock (Left: Next, Right: Prev, Middle: Quickapps)"
            onClicked: {
                Config.run("hyde-shell waybar -n");
            }
            onRightClicked: {
                Config.run("hyde-shell waybar -p");
            }
            onMiddleClicked: {
                Config.run("hyde-shell quickapps");
            }
        }

        // Clipboard History
        IslandButton {
            icon: ""
            tooltip: "Clipboard History"
            onClicked: {
                Config.run("sleep 0.1 && hyde-shell cliphist -c");
            }
        }

        // HyDE Menu
        IslandButton {
            icon: ""
            tooltip: "HyDE Menu"
            onClicked: {
                Config.run("hyde-shell logoutlaunch 1");
            }
        }

        // Power Menu
        IslandButton {
            icon: ""
            tooltip: "Power Menu (wlogout)"
            textColor: Config.danger
            hoverBgColor: Config.danger
            onClicked: {
                Config.run("wlogout || hyde-shell logoutlaunch 1");
            }
        }
    }
}
