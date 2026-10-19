pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    // Fonts & Dimensions
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 10
    readonly property int iconSize: 13
    
    readonly property int compactHeight: 34
    readonly property int expandedHeight: 52
    readonly property int compactWidth: 460
    readonly property int pillRadius: 17
    readonly property int innerPillRadius: 12

    // Apple Dynamic Island + Rose Pine Palette
    readonly property color islandBg: "#0d0e17"
    readonly property color islandBorder: "#26233a"
    readonly property color subPillBg: "#191724"
    readonly property color subPillBorder: "#21202e"
    
    readonly property color mainFg: "#ebbcba"
    readonly property color dimFg: "#908caa"
    
    readonly property color actBg: "#31748f"
    readonly property color actFg: "#9ccfd8"
    
    readonly property color hvrBg: "#eb6f92"
    readonly property color hvrFg: "#f6c177"
    
    readonly property color success: "#9ccfd8"
    readonly property color warning: "#f6c177"
    readonly property color danger: "#eb6f92"

    // Animation Settings
    readonly property int animDuration: 280
    readonly property int springDuration: 340

    // Global Interactive States
    property bool isPinned: false
    property bool isHovered: false
    property bool manualExpand: false

    readonly property bool expanded: isPinned || isHovered || manualExpand

    // Plug-and-Play Module Declarations
    // Reorder, remove, or add custom module names here without touching core code!
    property var compactModules: ["workspace", "window", "battery", "volume", "clock"]
    property var expandedLeft: ["sysmon", "workspaces"]
    property var expandedCenter: ["media", "taskbar"]
    property var expandedRight: ["audio", "backlight", "quicksettings", "battery"]

    // Global command runner
    Process {
        id: procRunner
    }

    function run(cmd) {
        if (!cmd) return;
        procRunner.exec(["sh", "-c", cmd]);
    }
}
