pragma Singleton
import QtQuick
import ".."

Item {
    id: root

    // Pending popup queue for incoming alerts
    property var alertQueue: []
    // History list of notification records (pure serializable primitives)
    property var historyList: []

    // Map of raw Notification objects indexed by ID for actions/dismiss
    property var liveNotifMap: ({})

    // Timer controlling how long the dynamic island stays popped open for an alert
    Timer {
        id: bannerTimer
        interval: 5000
        repeat: false
        onTriggered: {
            root.dismissActive();
        }
    }

    // Categorize notification into human-friendly app / system information
    function categorizeNotification(notif) {
        let appName = (notif.appName || "").trim();
        let desktopEntry = (notif.desktopEntry || "").toLowerCase().trim();
        let appIcon = (notif.appIcon || "").trim();
        let summary = (notif.summary || "").trim();
        let body = (notif.body || "").trim();

        let cleanAppName = appName;
        let cleanIcon = appIcon;
        let category = "app"; // "chat", "media", "system", "app"
        let badgeColor = "#0071e3";
        let badgeIcon = "󰂚";

        let lowerApp = appName.toLowerCase();
        let lowerIcon = appIcon.toLowerCase();

        // 1. Teams for Linux / Microsoft Teams
        if (lowerApp.includes("teams") || desktopEntry.includes("teams") || lowerIcon.includes("teams")) {
            cleanAppName = "Microsoft Teams";
            cleanIcon = cleanIcon || "teams-for-linux";
            category = "chat";
            badgeColor = "#5059C9"; // Teams purple/blue
            badgeIcon = "󰊻";
        }
        // 2. WhatsApp
        else if (lowerApp.includes("whatsapp") || desktopEntry.includes("whatsapp") || lowerIcon.includes("whatsapp")) {
            cleanAppName = "WhatsApp";
            cleanIcon = cleanIcon || "whatsapp";
            category = "chat";
            badgeColor = "#25D366"; // WhatsApp green
            badgeIcon = "󰖣";
        }
        // 3. Discord
        else if (lowerApp.includes("discord") || desktopEntry.includes("discord") || lowerIcon.includes("discord")) {
            cleanAppName = "Discord";
            cleanIcon = cleanIcon || "discord";
            category = "chat";
            badgeColor = "#5865F2";
            badgeIcon = "󰙯";
        }
        // 4. Slack
        else if (lowerApp.includes("slack") || desktopEntry.includes("slack") || lowerIcon.includes("slack")) {
            cleanAppName = "Slack";
            cleanIcon = cleanIcon || "slack";
            category = "chat";
            badgeColor = "#4A154B";
            badgeIcon = "󰒱";
        }
        // 5. Telegram
        else if (lowerApp.includes("telegram") || desktopEntry.includes("telegram") || lowerIcon.includes("telegram")) {
            cleanAppName = "Telegram";
            cleanIcon = cleanIcon || "telegram";
            category = "chat";
            badgeColor = "#2AABEE";
            badgeIcon = "󰀲";
        }
        // 6. Spotify / Music
        else if (lowerApp.includes("spotify") || lowerIcon.includes("spotify")) {
            cleanAppName = "Spotify";
            cleanIcon = cleanIcon || "spotify";
            category = "media";
            badgeColor = "#1DB954";
            badgeIcon = "";
        }
        // 7. System / Hardware / Power notifications
        else if (lowerApp.includes("power") || lowerApp.includes("battery") || lowerApp.includes("system") ||
                 lowerIcon.includes("battery") || lowerIcon.includes("dialog") || lowerApp === "" || lowerApp === "notify-send") {
            cleanAppName = "System";
            cleanIcon = cleanIcon || "dialog-information";
            category = "system";
            badgeColor = notif.urgency === 2 ? "#ff3b30" : "#86868b";
            badgeIcon = notif.urgency === 2 ? "󰀦" : "󰌢";
        }

        let cleanSender = summary;
        if (!cleanSender && cleanAppName) {
            cleanSender = cleanAppName;
        }

        return {
            appName: cleanAppName || "Notification",
            appIcon: cleanIcon,
            category: category,
            badgeColor: badgeColor,
            badgeIcon: badgeIcon,
            sender: cleanSender
        };
    }

    function handleIncomingNotification(notif) {
        if (!notif) return;

        try {
            notif.tracked = true;
        } catch (e) {}

        let meta = categorizeNotification(notif);

        // Convert actions to plain JSON objects (no QObject references)
        let plainActions = [];
        if (notif.actions) {
            for (let i = 0; i < notif.actions.length; i++) {
                let act = notif.actions[i];
                if (act) {
                    plainActions.push({
                        identifier: String(act.identifier || ""),
                        text: String(act.text || act.identifier || "")
                    });
                }
            }
        }

        let notifId = String(notif.id !== undefined ? notif.id : Date.now());

        // Keep raw C++ reference separately in liveNotifMap
        root.liveNotifMap[notifId] = notif;

        // Pure JS primitive record: SAFE for QVariantList / QML ListView models
        let record = {
            id: notifId,
            appName: String(meta.appName),
            appIcon: String(meta.appIcon),
            category: String(meta.category),
            badgeColor: String(meta.badgeColor),
            badgeIcon: String(meta.badgeIcon),
            sender: String(meta.sender),
            summary: String(notif.summary || meta.appName),
            body: String(notif.body || ""),
            urgency: Number(notif.urgency !== undefined ? notif.urgency : 1),
            actions: plainActions,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };

        // Add to history (newest first)
        let hist = root.historyList.slice();
        hist.unshift(record);
        if (hist.length > 50) hist.pop();
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
        if (Config.activeNotification && Config.activeNotification.id) {
            let notifObj = root.liveNotifMap[Config.activeNotification.id];
            if (notifObj) {
                try {
                    notifObj.dismiss();
                } catch (e) {}
            }
        }
        Config.isNotificationEventActive = false;
        Config.activeNotification = null;

        // Process next queued alert if any
        if (root.alertQueue.length > 0) {
            Qt.callLater(processNextAlert);
        }
    }

    function invokeAction(record, action) {
        if (record && record.id) {
            let notifObj = root.liveNotifMap[record.id];
            if (notifObj && notifObj.actions) {
                for (let i = 0; i < notifObj.actions.length; i++) {
                    let a = notifObj.actions[i];
                    if (a && a.identifier === action.identifier) {
                        try {
                            a.invoke();
                        } catch (e) {}
                        break;
                    }
                }
            }
        }
        dismissActive();
    }

    function clearHistory() {
        root.historyList = [];
        Config.notificationHistory = [];
        root.liveNotifMap = ({});
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
                        text: "Turn On Power Saver"
                    }
                ],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
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
                        text: "Review Changes"
                    },
                    {
                        identifier: "dismiss",
                        text: "Dismiss"
                    }
                ],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
        } else {
            // Normal
            notifRecord = {
                id: Date.now(),
                appName: "teams-for-linux",
                appIcon: "teams-for-linux",
                summary: "Liam Patterson",
                body: "Hey, are we still on for coffee later? I might be 10–15 minutes late, traffic looks...",
                urgency: 1,
                actions: [],
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
        }

        handleIncomingNotification(notifRecord);
    }
}
