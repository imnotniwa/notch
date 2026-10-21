pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    // Apple San Francisco / System Font with monospace fallbacks for clean typography
    readonly property string fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, 'Inter', 'JetBrainsMono Nerd Font', sans-serif"
    readonly property string monoFontFamily: "SF Mono, 'JetBrainsMono Nerd Font', 'Fira Code', monospace"
    readonly property string iconFont: "JetBrainsMono Nerd Font, 'Symbols Nerd Font', sans-serif"
    readonly property string bodyFont: fontFamily
    readonly property string monoFont: monoFontFamily
    readonly property int fontSize: 11
    readonly property int iconSize: 13
    
    readonly property int compactHeight: 38
    readonly property int expandedHeight: 146
    readonly property int deckWidth: 560
    readonly property int pillRadius: 24
    readonly property int innerPillRadius: 15

    // Gallery Deck State (0: Media, 1: Workspaces/Apps, 2: Hardware/SysMon, 3: Control Center/Tray)
    property int galleryIndex: 0

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
    property bool isDeckOpen: false
    property bool manualExpand: false
    property bool powerModalVisible: false
    property string activeAnchorEdge: "top"

    // Apple Context Menu State
    property var trayActiveMenu: null
    property real trayMenuX: 0
    property real trayMenuY: 0
    property bool trayMenuVisible: false

    // Power Connection Transient Event Banner (Apple Dynamic Island Style)
    property bool isPowerEventActive: false
    property bool lastAcOnline: true
    property string powerEventMessage: ""
    property string powerEventIcon: "󱐋"
    property color powerEventColor: "#34c759"

    // App Taskbar Context Menu State
    property var activeAppWindow: null
    property real appMenuX: 0
    property bool appMenuVisible: false

    // Auto-hide hanging notch state: strictly visible when hovered, pinned, manualExpand, power modal open, tray menu active, or app menu active
    property bool notchHovered: false
    readonly property bool notchVisible: notchHovered || isHovered || isPinned || manualExpand || powerModalVisible || trayMenuVisible || appMenuVisible || isDeckOpen || isPowerEventActive
    readonly property bool expanded: isPinned || isDeckOpen || powerModalVisible || trayMenuVisible || appMenuVisible

    // Notch Anchor Mode: "auto", "top", or "bottom"
    // "auto": intelligently detects if another monitor is stacked above this monitor.
    // If a monitor is underneath another (e.g. laptop below external), it anchors to "bottom" so the mouse transition across monitors isn't blocked.
    property string notchAnchor: "auto"

    function getAnchorForScreen(screen, allScreens) {
        if (!screen) return "top";
        if (notchAnchor === "top" || notchAnchor === "bottom") {
            return notchAnchor;
        }

        // Automatic detection for stacked monitors
        if (!allScreens || allScreens.length <= 1) return "top";

        let curX = screen.x;
        let curY = screen.y;
        let curW = screen.width;

        // Check if there is another monitor located directly above this one
        for (let i = 0; i < allScreens.length; i++) {
            let other = allScreens[i];
            if (other === screen) continue;
            
            // Check horizontal overlap
            let xOverlap = !(other.x + other.width <= curX || other.x >= curX + curW);
            // Check if other's bottom is near this screen's top (within 50px tolerance)
            let isAbove = (other.y + other.height >= curY - 50) && (other.y + other.height <= curY + 50);

            if (xOverlap && isAbove) {
                return "bottom";
            }
        }

        return "top";
    }

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
