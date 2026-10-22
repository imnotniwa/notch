pragma Singleton
import QtQuick
import ".."

Item {
    id: root

    // Pending popup queue for incoming alerts
    property var alertQueue: []
    // History list of notification records
    property var historyList: []

    // Timer controlling how long the dynamic island stays popped open for an alert
    Timer {
        id: bannerTimer
        interval: 5000
        repeat: false
        onTriggered: {
            root.dismissActive();
        }
    }

    function handleIncomingNotification(notif) {
        if (!notif) return;

        // Keep notif tracked so actions and dismissal can be handled cleanly
        try {
            notif.tracked = true;
        } catch (e) {}

        let record = {
            id: notif.id !== undefined ? notif.id : Date.now(),
            appName: notif.appName || "Notification",
            appIcon: notif.appIcon || "",
            summary: notif.summary || "",
            body: notif.body || "",
            urgency: notif.urgency !== undefined ? notif.urgency : 1, // 0: low, 1: normal, 2: critical
            actions: notif.actions || [],
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            rawNotif: notif
        };

        // Add to history (newest first)
        let hist = root.historyList.slice();
        hist.unshift(record);
        if (hist.length > 50) hist.pop(); // Cap history to 50
        root.historyList = hist;
        Config.notificationHistory = hist;

        // Add to popup queue
        let q = root.alertQueue.slice();
        q.push(record);
        root.alertQueue = q;

        if (!Config.isNotificationEventActive) {
            processNextAlert();
        }
    }

    function processNextAlert() {
        if (root.alertQueue.length === 0) {
            Config.isNotificationEventActive = false;
            Config.activeNotification = null;
            return;
        }

        let q = root.alertQueue.slice();
        let current = q.shift();
        root.alertQueue = q;

        Config.activeNotification = current;
        Config.isNotificationEventActive = true;

        // Critical alerts stay longer (8s), normal 5s, low 3.5s
        let timeout = 5000;
        if (current.urgency === 2) {
            timeout = 8000;
        } else if (current.urgency === 0) {
            timeout = 3500;
        }
        bannerTimer.interval = timeout;
        bannerTimer.restart();
    }

    function dismissActive() {
        bannerTimer.stop();
        if (Config.activeNotification && Config.activeNotification.rawNotif) {
            try {
                Config.activeNotification.rawNotif.dismiss();
            } catch (e) {}
        }
        Config.isNotificationEventActive = false;
        Config.activeNotification = null;

        // Process next queued alert if any
        if (root.alertQueue.length > 0) {
            Qt.callLater(processNextAlert);
        }
    }

    function invokeAction(record, action) {
        if (action && typeof action.invoke === "function") {
            try {
                action.invoke();
            } catch (e) {}
        }
        dismissActive();
    }

    function clearHistory() {
        root.historyList = [];
        Config.notificationHistory = [];
    }

    // Trigger local interactive test notifications for immediate visual verification
    function triggerTestNotification(type) {
        let notifRecord = {};

        if (type === "critical") {
            notifRecord = {
                id: Date.now(),
                appName: "Battery Warning",
                appIcon: "battery-caution",
                summary: "Battery Critically Low",
                body: "Battery is at 10%. Connect power adapter now to avoid shutdown.",
                urgency: 2,
                actions: [
                    {
                        identifier: "powersave",
                        text: "Turn On Power Saver",
                        invoke: function() { console.log("Power Saver Invoked"); }
                    }
                ],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                rawNotif: null
            };
        } else if (type === "actions") {
            notifRecord = {
                id: Date.now(),
                appName: "GitHub",
                appIcon: "github",
                summary: "Pull Request #42",
                body: "alice requested your review on: feat(notch): dynamic notifications",
                urgency: 1,
                actions: [
                    {
                        identifier: "review",
                        text: "Review Changes",
                        invoke: function() { console.log("Review Changes Invoked"); }
                    },
                    {
                        identifier: "dismiss",
                        text: "Dismiss",
                        invoke: function() { root.dismissActive(); }
                    }
                ],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                rawNotif: null
            };
        } else {
            // Normal
            notifRecord = {
                id: Date.now(),
                appName: "Slack",
                appIcon: "slack",
                summary: "Team Sync Started",
                body: "Frontend Architecture discussion is live in #engineering.",
                urgency: 1,
                actions: [],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                rawNotif: null
            };
        }

        // Add to history
        let hist = root.historyList.slice();
        hist.unshift(notifRecord);
        root.historyList = hist;
        Config.notificationHistory = hist;

        // Push to alert banner
        let q = root.alertQueue.slice();
        q.push(notifRecord);
        root.alertQueue = q;

        if (!Config.isNotificationEventActive) {
            processNextAlert();
        }
    }
}
