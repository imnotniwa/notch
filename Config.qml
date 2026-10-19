pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    // Fonts & Dimensions
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 10
    readonly property int iconSize: 13
    
    readonly property int compactHeight: 32
    readonly property int expandedHeight: 50
    readonly property int compactWidth: 440
    readonly property int pillRadius: 16
    readonly property int innerPillRadius: 11

    // Apple Dynamic Island + Rose Pine Palette
    // Pure pitch OLED black for the outer island capsule
    readonly property color islandBg: "#000000"
    // Delicate specular rim that catches the light
    readonly property color islandBorder: Qt.rgba(1, 1, 1, 0.14)
    readonly property color subPillBg: Qt.rgba(1, 1, 1, 0.07)
    readonly property color subPillBorder: Qt.rgba(1, 1, 1, 0.08)
    
    // High contrast vibrant typography
    readonly property color mainFg: "#f0f0f5"
    readonly property color dimFg: "#9898a6"
    
    // Apple vibrant system accents
    readonly property color actBg: "#0a84ff"
    readonly property color actFg: "#ffffff"
    
    readonly property color hvrBg: "#eb6f92"
    readonly property color hvrFg: "#ffffff"
    
    readonly property color success: "#30d158"
    readonly property color warning: "#ffd60a"
    readonly property color danger: "#ff453a"

    // Apple Spring Dynamics
    // Damping ~1.0 with subtle natural settling
    readonly property int animDuration: 240
    readonly property int springDuration: 300

    // Global Interactive States
    property bool isPinned: false
    property bool isHovered: false
    property bool manualExpand: false
    property bool powerModalVisible: false

    // Auto-hide hanging notch state: visible if hovered, pinned, manualExpand, or power modal open
    property bool notchHovered: false
    readonly property bool notchVisible: notchHovered || isHovered || isPinned || manualExpand || powerModalVisible
    readonly property bool expanded: isPinned || (isHovered && notchVisible) || manualExpand

    // Plug-and-Play Module Declarations
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
