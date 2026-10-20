pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    // Apple San Francisco / System Font with monospace fallbacks for clean typography
    readonly property string fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, 'Inter', 'JetBrainsMono Nerd Font', sans-serif"
    readonly property string monoFontFamily: "SF Mono, 'JetBrainsMono Nerd Font', 'Fira Code', monospace"
    readonly property int fontSize: 11
    readonly property int iconSize: 13
    
    readonly property int expandedHeight: 46
    readonly property int pillRadius: 23
    readonly property int innerPillRadius: 15

    // Apple Dynamic Island Material System
    // Pitch OLED black for seamless bezel integration
    readonly property color islandBg: "#000000"
    // Specular highlight rim: authentic Apple dark glass reflection
    readonly property color islandBorder: Qt.rgba(1, 1, 1, 0.12)
    // Translucent dark glass inner capsules
    readonly property color subPillBg: Qt.rgba(1, 1, 1, 0.08)
    readonly property color subPillBorder: Qt.rgba(1, 1, 1, 0.07)
    
    // High contrast vibrant typography
    readonly property color mainFg: "#f5f5f7"
    readonly property color dimFg: "#86868b"
    
    // Apple vibrant system accents (WWDC standard)
    readonly property color actBg: "#0071e3"
    readonly property color actFg: "#ffffff"
    
    readonly property color hvrBg: Qt.rgba(1, 1, 1, 0.14)
    readonly property color hvrFg: "#ffffff"
    
    readonly property color success: "#34c759"
    readonly property color warning: "#ff9f0a"
    readonly property color danger: "#ff3b30"

    // Apple Spring Dynamics
    // Damping ~1.0 with subtle natural settling
    readonly property int animDuration: 240
    readonly property int springDuration: 300

    // Global Interactive States
    property bool isPinned: false
    property bool isHovered: false
    property bool manualExpand: false
    property bool powerModalVisible: false

    // Apple Context Menu State
    property var trayActiveMenu: null
    property real trayMenuX: 0
    property real trayMenuY: 0
    property bool trayMenuVisible: false

    // Auto-hide hanging notch state: strictly visible when hovered, pinned, manualExpand, power modal open, or tray menu active
    property bool notchHovered: false
    readonly property bool notchVisible: notchHovered || isHovered || isPinned || manualExpand || powerModalVisible || trayMenuVisible
    readonly property bool expanded: notchVisible

    // Plug-and-Play Module Declarations
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
