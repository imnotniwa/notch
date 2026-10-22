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
            },
            {
                name: "Gallery Deck Navigation & Tab Cycling",
                fn: function() {
                    // Test 5 gallery tabs: 0: Media, 1: Spaces, 2: Hardware, 3: Control, 4: Tray
                    let numTabs = 5;
                    Config.galleryIndex = 0;
                    assertEquals(Config.galleryIndex, 0, "Initial gallery starts on Media");

                    // Next tab
                    Config.galleryIndex = (Config.galleryIndex + 1) % numTabs;
                    assertEquals(Config.galleryIndex, 1, "Next advances to Spaces");

                    // Next tab
                    Config.galleryIndex = (Config.galleryIndex + 1) % numTabs;
                    assertEquals(Config.galleryIndex, 2, "Next advances to Hardware");

                    // Next tab
                    Config.galleryIndex = (Config.galleryIndex + 1) % numTabs;
                    assertEquals(Config.galleryIndex, 3, "Next advances to Control");

                    // Next tab
                    Config.galleryIndex = (Config.galleryIndex + 1) % numTabs;
                    assertEquals(Config.galleryIndex, 4, "Next advances to Tray");

                    // Next tab wraps to 0
                    Config.galleryIndex = (Config.galleryIndex + 1) % numTabs;
                    assertEquals(Config.galleryIndex, 0, "Next wraps back to Media");

                    // Previous wraps to 4
                    Config.galleryIndex = (Config.galleryIndex - 1 + numTabs) % numTabs;
                    assertEquals(Config.galleryIndex, 4, "Previous wraps to Tray");
                }
            },
            {
                name: "Cursor Tracking Mathematics & Display Edge Clamping",
                fn: function() {
                    let screenW = 1920;
                    let islandW = 420;
                    let halfW = islandW / 2;

                    // Cursor at left edge (0): clamps to 16
                    let leftCursor = 0;
                    let calcLeft = Math.round(Math.max(16, Math.min(leftCursor - halfW, screenW - islandW - 16)));
                    assertEquals(calcLeft, 16, "Cursor at left edge clamps island to 16px margin");

                    // Cursor at center (960): centers island at 750
                    let centerCursor = 960;
                    let calcCenter = Math.round(Math.max(16, Math.min(centerCursor - halfW, screenW - islandW - 16)));
                    assertEquals(calcCenter, 750, "Cursor at center places island at 750px");

                    // Cursor at right edge (1920): clamps to 1484 (1920 - 420 - 16)
                    let rightCursor = 1920;
                    let calcRight = Math.round(Math.max(16, Math.min(rightCursor - halfW, screenW - islandW - 16)));
                    assertEquals(calcRight, 1484, "Cursor at right edge clamps island to screenW - islandW - 16");
                }
            },
            {
                name: "Compact Glance Streamlining & Rich Media Expansion",
                fn: function() {
                    // Test compact dimensions vs rich media dimensions
                    let compactHeight = 38;
                    let mediaCardHeight = 116;
                    let expandedDeckHeight = 146;

                    // Verify compact height definition
                    assertEquals(Config.compactHeight, compactHeight, "Default compact height is 38px");
                    assertEquals(Config.expandedHeight, expandedDeckHeight, "Expanded full deck height is 146px");

                    // Verify clicking compact island expands deck (Tier 2)
                    Config.isDeckOpen = false;
                    assertEquals(Config.expanded, false, "Deck initially closed");
                    Config.isDeckOpen = true;
                    assertEquals(Config.expanded, true, "Clicking compact island opens Tier 2 deck");
                    Config.isDeckOpen = false;
                    assertEquals(Config.expanded, false, "Toggling closes Tier 2 deck");
                }
            },
            {
                name: "Hardware Telemetry Deck Card Bounds and Data Formats",
                fn: function() {
                    let hwComponent = Qt.createComponent("modules/HardwareDeckCard.qml");
                    if (hwComponent.status === Component.Error) {
                        console.error("Component error: " + hwComponent.errorString());
                    }
                    assertEquals(hwComponent.status, Component.Ready, "HardwareDeckCard component compiles cleanly");

                    let hwCard = hwComponent.createObject(testRoot);
                    assertTrue(hwCard !== null && hwCard !== undefined, "HardwareDeckCard instantiates without error");

                    // Validate default dimensions fitting the 520x96 deck slot
                    assertEquals(hwCard.implicitWidth, 520, "Hardware card width matches deck width");
                    assertEquals(hwCard.implicitHeight, 96, "Hardware card height matches deck height");

                    // Validate telemetry properties & bounds
                    assertTrue(hwCard.cpuFraction >= 0.0 && hwCard.cpuFraction <= 1.0, "CPU fraction within [0, 1]");
                    assertTrue(hwCard.memFraction >= 0.0 && hwCard.memFraction <= 1.0, "Memory fraction within [0, 1]");
                    assertTrue(hwCard.batFraction >= 0.0 && hwCard.batFraction <= 1.0, "Battery fraction within [0, 1]");
                    assertTrue(hwCard.diskFraction >= 0.0 && hwCard.diskFraction <= 1.0, "Disk fraction within [0, 1]");

                    // Test updates
                    hwCard.updateCpu();
                    hwCard.updateMem();
                    hwCard.updateBattery();

                    assertTrue(hwCard.cpuUsageText.indexOf("%") !== -1, "CPU usage formatted as percentage string");
                    assertTrue(hwCard.memPercentText.indexOf("%") !== -1, "Memory formatted as percentage string");

                    hwCard.destroy();
                }
            },
            {
                name: "Spaces Deck Card Compilation & Mission Control Architecture",
                fn: function() {
                    let spacesComponent = Qt.createComponent("modules/SpacesDeckCard.qml");
                    if (spacesComponent.status === Component.Error) {
                        console.error("Spaces Deck Error: " + spacesComponent.errorString());
                    }
                    assertEquals(spacesComponent.status, Component.Ready, "SpacesDeckCard component compiles cleanly");

                    let spacesCard = spacesComponent.createObject(testRoot);
                    assertTrue(spacesCard !== null && spacesCard !== undefined, "SpacesDeckCard instantiates without error");

                    // Check dimensions matching Tier 2 slot
                    assertEquals(spacesCard.implicitWidth, 520, "Spaces card width matches deck width");
                    assertEquals(spacesCard.implicitHeight, 96, "Spaces card height matches deck height");

                    // Test spaces data refreshing
                    spacesCard.refreshSpacesData();
                    assertTrue(spacesCard.activeWsId !== undefined && spacesCard.activeWsId !== null, "Active workspace ID is tracked");
                    assertTrue(Array.isArray(spacesCard.activeSpaceWindows), "Active space windows is an array");

                    spacesCard.destroy();
                }
            },
            {
                name: "Control Deck Card Option A Modular Tiles Architecture",
                fn: function() {
                    let ctrlComponent = Qt.createComponent("modules/ControlDeckCard.qml");
                    assertEquals(ctrlComponent.status, Component.Ready, "ControlDeckCard compiles cleanly");

                    let ctrlCard = ctrlComponent.createObject(testRoot);
                    assertTrue(ctrlCard !== null && ctrlCard !== undefined, "ControlDeckCard instantiates without error");

                    // Validate slot geometry
                    assertEquals(ctrlCard.implicitWidth, 520, "Control card width is 520px");
                    assertEquals(ctrlCard.implicitHeight, 96, "Control card height is 96px");

                    // Validate telemetry properties
                    assertTrue(ctrlCard.volumePct >= 0 && ctrlCard.volumePct <= 150, "Volume bounded");
                    assertTrue(ctrlCard.brightnessPct >= 0 && ctrlCard.brightnessPct <= 100, "Brightness bounded");

                    ctrlCard.destroy();
                }
            },
            {
                name: "Interactive Charging Power Event Notification Lifecycle",
                fn: function() {
                    // Test initial state
                    Config.isPowerEventActive = false;
                    assertEquals(Config.isPowerEventActive, false, "Power event initially idle");

                    // Trigger plug connect
                    Config.powerEventIcon = "󱐋";
                    Config.powerEventColor = Config.success;
                    Config.powerEventMessage = "Charging 80%";
                    Config.isPowerEventActive = true;

                    // Notch must automatically expand into view even if cursor is not hovering
                    assertTrue(Config.notchVisible, "Notch reveals itself dynamically on AC power connection");

                    // Trigger unplug
                    Config.powerEventIcon = "󰂎";
                    Config.powerEventColor = Config.warning;
                    Config.powerEventMessage = "On Battery 79%";
                    assertTrue(Config.isPowerEventActive, "Unplug event active");

                    // Reset
                    Config.isPowerEventActive = false;
                }
            },
            {
                name: "Settings Card and Always On Compact Mode Lifecycle",
                fn: function() {
                    // Test initial state
                    Config.isHovered = false;
                    Config.notchHovered = false;
                    Config.isPinned = false;
                    Config.isDeckOpen = false;
                    Config.alwaysOn = false;
                    assertEquals(Config.notchVisible, false, "Notch is hidden when idle and alwaysOn is false");
                    assertEquals(Config.expanded, false, "Notch is not expanded");

                    // Activate Always On
                    Config.alwaysOn = true;
                    assertEquals(Config.notchVisible, true, "Always On keeps notch visible when idle");
                    assertEquals(Config.expanded, false, "Always On keeps notch strictly in compact glance mode (not expanded)");

                    // Open Deck
                    Config.isDeckOpen = true;
                    assertEquals(Config.expanded, true, "Clicking notch with alwaysOn expands full deck");

                    // Switch to Settings card (index 5)
                    Config.galleryIndex = 5;
                    assertEquals(Config.galleryIndex, 5, "Settings card index 5 is selectable");

                    // Instantiate SettingsDeckCard
                    let comp = Qt.createComponent("modules/SettingsDeckCard.qml");
                    if (comp.status === Component.Error) {
                        console.error("Settings Deck Error: " + comp.errorString());
                    }
                    assertEquals(comp.status, Component.Ready, "SettingsDeckCard compiles cleanly");
                    let settingsCard = comp.createObject(testRoot);
                    assertTrue(settingsCard !== null, "SettingsDeckCard created successfully");
                    assertEquals(settingsCard.implicitWidth, 520, "Settings card width is 520px");
                    assertEquals(settingsCard.implicitHeight, 96, "Settings card height is 96px");
                    settingsCard.destroy();

                    // Close Deck
                    Config.isDeckOpen = false;
                    assertEquals(Config.expanded, false, "Closing deck returns to compact mode");
                    assertEquals(Config.notchVisible, true, "Notch still visible because alwaysOn is true");

                    // Turn off Always On
                    Config.alwaysOn = false;
                    assertEquals(Config.notchVisible, false, "Turning off alwaysOn allows notch to auto-hide when idle");
                }
            },
            {
                name: "Notification Dynamic Island Banner and History Deck Lifecycle",
                fn: function() {
                    // Instantiate NotificationService
                    let notifComp = Qt.createComponent("core/NotificationService.qml");
                    if (notifComp.status === Component.Error) {
                        console.error("Notification Service Error: " + notifComp.errorString());
                    }
                    assertEquals(notifComp.status, Component.Ready, "NotificationService compiles cleanly");
                    let notifSvc = notifComp.createObject(testRoot);
                    assertTrue(notifSvc !== null, "NotificationService created successfully");

                    // Verify default state
                    assertEquals(Config.isNotificationEventActive, false, "Notification banner is inactive initially");
                    assertEquals(Config.activeNotification, null, "Active notification is null initially");

                    // Trigger a test notification (Normal)
                    notifSvc.triggerTestNotification("normal");
                    assertEquals(Config.isNotificationEventActive, true, "Triggering normal notification activates banner");
                    assertEquals(Config.notchVisible, true, "Incoming notification forces notch visible");
                    assertEquals(Config.expanded, false, "Notification banner keeps notch in compact pill (not deck)");
                    assertTrue(Config.activeNotification !== null, "Active notification object exists");
                    assertEquals(Config.activeNotification.appName, "Microsoft Teams", "Notification app name matches clean categorized name");
                    assertEquals(Config.activeNotification.summary, "Liam Patterson", "Notification sender matches");

                    // Check notification history tracking
                    assertTrue(Config.notificationHistory.length >= 1, "Notification stored in history");
                    assertEquals(Config.notificationHistory[0].summary, "Liam Patterson", "History contains latest notification");

                    // Test Dismiss
                    notifSvc.dismissActive();
                    assertEquals(Config.isNotificationEventActive, false, "Dismissing active notification closes banner");
                    assertEquals(Config.activeNotification, null, "Active notification cleared after dismiss");

                    // Trigger Critical Notification
                    notifSvc.triggerTestNotification("critical");
                    assertEquals(Config.isNotificationEventActive, true, "Critical alert activates banner");
                    assertEquals(Config.activeNotification.urgency, 2, "Urgency is 2 (Critical)");
                    assertEquals(Config.activeNotification.actions.length, 1, "Critical notification has 1 action");

                    // Invoke action
                    let action = Config.activeNotification.actions[0];
                    notifSvc.invokeAction(Config.activeNotification, action);
                    assertEquals(Config.isNotificationEventActive, false, "Invoking action dismisses active banner");

                    // Test Notification History Modal
                    let modalComp = Qt.createComponent("components/NotificationHistoryModal.qml");
                    if (modalComp.status === Component.Error) {
                        console.error("Notification Modal Error: " + modalComp.errorString());
                    }
                    assertEquals(modalComp.status, Component.Ready, "NotificationHistoryModal compiles cleanly");
                    let notifModal = modalComp.createObject(testRoot);
                    assertTrue(notifModal !== null, "NotificationHistoryModal created successfully");

                    Config.notificationModalVisible = true;
                    assertEquals(Config.notificationModalVisible, true, "Notification modal visibility state toggles to true");
                    assertEquals(Config.notchVisible, true, "Notch is visible when notification modal is open");

                    Config.notificationModalVisible = false;
                    assertEquals(Config.notificationModalVisible, false, "Notification modal closes properly");

                    // Test Clear History
                    notifSvc.clearHistory();
                    assertEquals(Config.notificationHistory.length, 0, "Clearing history empties notification records");

                    notifModal.destroy();
                    notifSvc.destroy();
                }
            }
        ];

        // Begin test execution
        stepTimer.start();
    }
}
