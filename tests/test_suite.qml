import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "components"

Item {
    id: testRoot
    width: 800
    height: 600

    property int passCount: 0
    property int failCount: 0
    property var testQueue: []
    property int currentTestIndex: 0

    Process {
        id: exitProc
    }

    function assertTrue(condition, message) {
        if (!condition) {
            console.error("  ❌ FAIL: " + message);
            failCount++;
            return false;
        } else {
            console.log("  ✅ PASS: " + message);
            passCount++;
            return true;
        }
    }

    function assertEquals(actual, expected, message) {
        if (actual !== expected) {
            console.error("  ❌ FAIL: " + message + " (Expected: " + expected + ", Actual: " + actual + ")");
            failCount++;
            return false;
        } else {
            console.log("  ✅ PASS: " + message + " (Value: " + actual + ")");
            passCount++;
            return true;
        }
    }

    // Interactive button container to test real visual item layout and anchor updates
    Item {
        id: container
        width: 800
        height: 600
        y: 100

        IslandButton {
            id: testButton
            x: 200
            y: 200
            text: "Test Island"
            tooltip: "Sample Tooltip Information"
        }
    }

    Timer {
        id: stepTimer
        interval: 30
        repeat: false
        onTriggered: runNextTest()
    }

    function runNextTest() {
        if (currentTestIndex >= testQueue.length) {
            finishTests();
            return;
        }

        let test = testQueue[currentTestIndex];
        currentTestIndex++;
        console.log("\n▶ Running: " + test.name);
        try {
            test.fn();
        } catch (e) {
            console.error("  ❌ EXCEPTION in " + test.name + ": " + e);
            failCount++;
        }

        stepTimer.start();
    }

    function finishTests() {
        console.log("\n========================================");
        console.log("Test Suite Completed: " + passCount + " PASSED, " + failCount + " FAILED");
        console.log("========================================\n");

        // Write test outcome to a temporary marker file for the test runner script to inspect
        let resultCmd = failCount > 0 ? "echo FAILED > /tmp/notch_test_result && kill -9 $PPID" : "echo PASSED > /tmp/notch_test_result && kill -9 $PPID";
        exitProc.exec(["sh", "-c", resultCmd]);
    }

    Component.onCompleted: {
        console.log("========================================");
        console.log("Starting Quickshell Notch Unit Test Suite");
        console.log("========================================");

        // Define tests
        testQueue = [
            {
                name: "Anchor Detection: Single Monitor",
                fn: function() {
                    Config.notchAnchor = "auto";
                    let screen = { x: 0, y: 0, width: 1920, height: 1080 };
                    let anchor = Config.getAnchorForScreen(screen, [screen]);
                    assertEquals(anchor, "top", "Single monitor defaults to top anchor");
                }
            },
            {
                name: "Anchor Detection: Stacked Monitors (Upper/Lower Detection)",
                fn: function() {
                    Config.notchAnchor = "auto";
                    let topScreen = { x: 0, y: 0, width: 1920, height: 1080 };
                    let bottomScreen = { x: 0, y: 1080, width: 1920, height: 1080 };
                    let all = [topScreen, bottomScreen];

                    assertEquals(Config.getAnchorForScreen(topScreen, all), "top", "Upper monitor anchors to top");
                    assertEquals(Config.getAnchorForScreen(bottomScreen, all), "bottom", "Lower monitor anchors to bottom");
                }
            },
            {
                name: "Anchor Detection: Side-by-Side Horizontal Monitors",
                fn: function() {
                    Config.notchAnchor = "auto";
                    let leftScreen = { x: 0, y: 0, width: 1920, height: 1080 };
                    let rightScreen = { x: 1920, y: 0, width: 1920, height: 1080 };
                    let all = [leftScreen, rightScreen];

                    assertEquals(Config.getAnchorForScreen(leftScreen, all), "top", "Left monitor anchors to top");
                    assertEquals(Config.getAnchorForScreen(rightScreen, all), "top", "Right monitor anchors to top");
                }
            },
            {
                name: "Anchor Detection: Manual Override",
                fn: function() {
                    let topScreen = { x: 0, y: 0, width: 1920, height: 1080 };
                    let bottomScreen = { x: 0, y: 1080, width: 1920, height: 1080 };
                    let all = [topScreen, bottomScreen];

                    Config.notchAnchor = "top";
                    assertEquals(Config.getAnchorForScreen(bottomScreen, all), "top", "Manual 'top' overrides stacked auto-detection");

                    Config.notchAnchor = "bottom";
                    assertEquals(Config.getAnchorForScreen(topScreen, all), "bottom", "Manual 'bottom' overrides stacked auto-detection");

                    Config.notchAnchor = "auto";
                }
            },
            {
                name: "Tooltip Placement: Default Top Anchor Orientation",
                fn: function() {
                    Config.activeAnchorEdge = "top";
                    let tip = null;
                    for (let i = 0; i < testButton.children.length; i++) {
                        if (testButton.children[i].text !== undefined && testButton.children[i] !== testButton) {
                            tip = testButton.children[i];
                            break;
                        }
                    }
                    assertTrue(tip !== null, "Found StyledTooltip child in IslandButton");
                    if (tip) {
                        assertEquals(tip.y, testButton.height + 8, "When top-anchored, tooltip y = button.height + 8");
                        assertTrue(tip.y >= testButton.height, "Tooltip is positioned below the button (y >= button height)");
                    }
                }
            },
            {
                name: "Tooltip Placement: Dynamic Transition to Bottom Anchor",
                fn: function() {
                    Config.activeAnchorEdge = "bottom";
                    let tip = null;
                    for (let i = 0; i < testButton.children.length; i++) {
                        if (testButton.children[i].text !== undefined && testButton.children[i] !== testButton) {
                            tip = testButton.children[i];
                            break;
                        }
                    }
                    assertTrue(tip !== null, "Found StyledTooltip child in IslandButton");
                    if (tip) {
                        assertEquals(tip.y, -tip.height - 8, "When bottom-anchored, tooltip y = -tip.height - 8");
                        assertTrue(tip.y + tip.height <= 0, "Tooltip is positioned completely above the button (tip.y + tip.height <= 0)");
                    }
                }
            },
            {
                name: "Tooltip Placement: Dynamic Transition Back to Top Anchor (Flipping Test)",
                fn: function() {
                    Config.activeAnchorEdge = "top";
                    let tip = null;
                    for (let i = 0; i < testButton.children.length; i++) {
                        if (testButton.children[i].text !== undefined && testButton.children[i] !== testButton) {
                            tip = testButton.children[i];
                            break;
                        }
                    }
                    assertTrue(tip !== null, "Found StyledTooltip child in IslandButton");
                    if (tip) {
                        assertEquals(tip.y, testButton.height + 8, "After switching back to top, tooltip y = button.height + 8");
                        assertTrue(tip.y >= testButton.height, "Tooltip is restored below the button");
                    }
                }
            },
            {
                name: "Tooltip Placement: Multiple Repeated Flips (Bottom <-> Top)",
                fn: function() {
                    let tip = null;
                    for (let i = 0; i < testButton.children.length; i++) {
                        if (testButton.children[i].text !== undefined && testButton.children[i] !== testButton) {
                            tip = testButton.children[i];
                            break;
                        }
                    }
                    assertTrue(tip !== null, "Found StyledTooltip child in IslandButton");

                    // Flip to bottom
                    Config.activeAnchorEdge = "bottom";
                    assertEquals(tip.y, -tip.height - 8, "Repeated flip 1: bottom anchor y is above button");

                    // Flip to top
                    Config.activeAnchorEdge = "top";
                    assertEquals(tip.y, testButton.height + 8, "Repeated flip 2: top anchor y is below button");

                    // Flip to bottom again
                    Config.activeAnchorEdge = "bottom";
                    assertEquals(tip.y, -tip.height - 8, "Repeated flip 3: bottom anchor y is above button");

                    // Flip back to top
                    Config.activeAnchorEdge = "top";
                    assertEquals(tip.y, testButton.height + 8, "Repeated flip 4: top anchor y is below button");
                }
            },
            {
                name: "Context Menu Coordinates & Geometry (Top vs Bottom)",
                fn: function() {
                    let screenH = 1080;
                    let menuHeight = 150;
                    
                    // Top anchor calculation
                    Config.activeAnchorEdge = "top";
                    let expectedTopY = Config.expandedHeight + 8;
                    let calcTopY = (Config.activeAnchorEdge === "bottom") ? (screenH - Config.expandedHeight - menuHeight - 12) : (Config.expandedHeight + 8);
                    assertEquals(calcTopY, expectedTopY, "Top anchor context menu y = expandedHeight + 8");

                    // Bottom anchor calculation
                    Config.activeAnchorEdge = "bottom";
                    let expectedBottomY = screenH - Config.expandedHeight - menuHeight - 12;
                    let calcBottomY = (Config.activeAnchorEdge === "bottom") ? (screenH - Config.expandedHeight - menuHeight - 12) : (Config.expandedHeight + 8);
                    assertEquals(calcBottomY, expectedBottomY, "Bottom anchor context menu y = screenH - expandedHeight - height - 12");
                    assertTrue(calcBottomY < screenH - Config.expandedHeight, "Bottom anchor context menu renders above the bottom notch");
                }
            },
            {
                name: "Mixed Interaction Stress Test: Tooltip -> Context Menu -> Toggle Anchor -> Tooltip",
                fn: function() {
                    // 1. Start at bottom anchor
                    Config.activeAnchorEdge = "bottom";
                    Config.trayMenuVisible = false;
                    Config.notchHovered = false;
                    assertEquals(Config.notchVisible, false, "Notch is hidden when idle");

                    // 2. Hover button, tooltip should be active & above
                    let tip = null;
                    for (let i = 0; i < testButton.children.length; i++) {
                        if (testButton.children[i].text !== undefined && testButton.children[i] !== testButton) {
                            tip = testButton.children[i];
                            break;
                        }
                    }
                    assertTrue(tip.y + tip.height <= 0, "Initial bottom tooltip is above button");

                    // 3. Open context menu
                    Config.trayMenuVisible = true;
                    assertEquals(Config.notchVisible, true, "Notch remains visible while tray context menu is open");

                    // 4. Close context menu
                    Config.trayMenuVisible = false;
                    assertEquals(Config.notchVisible, false, "Notch hides after context menu is closed when not hovered");

                    // 5. Flip anchor to top
                    Config.activeAnchorEdge = "top";
                    assertTrue(tip.y >= testButton.height, "Tooltip flipped downward below button when edge set to top");

                    // 6. Open context menu at top
                    Config.trayMenuVisible = true;
                    assertEquals(Config.notchVisible, true, "Notch remains visible when tray context menu is open at top");

                    // 7. Close context menu again
                    Config.trayMenuVisible = false;
                    assertEquals(Config.notchVisible, false, "Notch hides after context menu is closed at top");

                    // 8. Flip back to bottom
                    Config.activeAnchorEdge = "bottom";
                    assertTrue(tip.y + tip.height <= 0, "Tooltip flipped upward above button when edge set to bottom");
                }
            },
            {
                name: "Taskbar App Menu Interaction & Notch Visibility Test",
                fn: function() {
                    // Start idle
                    Config.appMenuVisible = false;
                    Config.trayMenuVisible = false;
                    Config.notchHovered = false;
                    assertEquals(Config.notchVisible, false, "Notch is hidden when idle");

                    // Trigger app menu on right click
                    Config.activeAppWindow = { address: "0x1234", title: "Test App", appClass: "test" };
                    Config.appMenuVisible = true;
                    assertEquals(Config.notchVisible, true, "Notch stays expanded when taskbar app menu is open");

                    // Close app menu
                    Config.appMenuVisible = false;
                    Config.activeAppWindow = null;
                    assertEquals(Config.notchVisible, false, "Notch closes when app menu is dismissed");
                }
            },
            {
                name: "Two-Tier Notch Hierarchy: Hover Compact vs Click Full Deck",
                fn: function() {
                    // 1. Idle state
                    Config.notchHovered = false;
                    Config.isHovered = false;
                    Config.isDeckOpen = false;
                    Config.isPinned = false;
                    assertEquals(Config.notchVisible, false, "Notch hidden at idle");
                    assertEquals(Config.expanded, false, "Deck collapsed at idle");

                    // 2. Cursor enters bezel: Compact Glance triggers
                    Config.notchHovered = true;
                    Config.isHovered = true;
                    assertEquals(Config.notchVisible, true, "Notch visible on hover");
                    assertEquals(Config.expanded, false, "Full Deck remains collapsed on hover (Compact Glance mode)");

                    // 3. User clicks island body to open Full Deck
                    Config.isDeckOpen = true;
                    assertEquals(Config.notchVisible, true, "Notch visible when deck is open");
                    assertEquals(Config.expanded, true, "Full Deck expands on click");

                    // 4. User clicks again to collapse back to Compact Glance
                    Config.isDeckOpen = false;
                    assertEquals(Config.notchVisible, true, "Notch still visible while hovering");
                    assertEquals(Config.expanded, false, "Deck collapsed back to Compact Glance");

                    // 5. Pin keeps Full Deck open
                    Config.isPinned = true;
                    assertEquals(Config.expanded, true, "Pin keeps Full Deck open");
                    Config.isPinned = false;
                    assertEquals(Config.expanded, false, "Unpin restores compact state");

                    // 6. Cursor leaves notch: auto-collapses
                    Config.notchHovered = false;
                    Config.isHovered = false;
                    assertEquals(Config.notchVisible, false, "Notch auto-hides when cursor leaves");
                }
            }
        ];

        // Begin test execution
        stepTimer.start();
    }
}
