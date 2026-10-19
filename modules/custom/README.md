# Custom Notch Modules (Plug & Play)

This directory is designed for **plug-and-play** custom modules!

## How to add your own module:

1. Create a `.qml` file in this directory (e.g. `MyWidget.qml`):
```qml
import QtQuick
import "../components"
import "../core"
import ".."

Item {
    id: root
    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    IslandButton {
        id: btn
        icon: "󰄛"
        text: "Custom"
        tooltip: "My Custom Module"
        onClicked: {
            Config.run("notify-send 'Custom module clicked!'");
        }
    }
}
```

2. To place it inside an `IslandPill` anywhere in `Island.qml`, simply wrap it in an `IslandPill`:
```qml
IslandPill {
    MyWidget {}
}
```

3. You have access to:
- `Config.run("any-shell-command")` - Executes shell commands cleanly
- `HyprlandLua.focusWorkspace(id)` - Switch Hyprland workspace via Lua dispatcher
- `HyprlandLua.focusWindow(address)` - Focus window
- `HyprlandLua.fullscreenWindow()` - Toggle fullscreen
- `HyprlandLua.closeWindow(address)` - Close window
- `HyprlandLua.lock()` - Lock screen (`hyprlock`)
- `Config.mainFg`, `Config.actBg`, `Config.hvrBg`, etc. - Theme colors
