pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    // Central shared task list: [{ id, text, time, completed, completedAt }]
    property var todos: [
        {
            id: 1,
            text: "Design review presentation",
            time: "3:00 PM · Studio 2",
            completed: false,
            completedAt: 0
        },
        {
            id: 2,
            text: "Gym workout session",
            time: "5:30 PM · 45 min",
            completed: false,
            completedAt: 0
        },
        {
            id: 3,
            text: "Team Sync & Planning",
            time: "7:00 PM · Google Meet",
            completed: false,
            completedAt: 0
        },
        {
            id: 4,
            text: "Push release notes & tag v1.0",
            time: "Today",
            completed: true,
            completedAt: 0
        }
    ]

    // Grace period for completed items to remain visible in Home tab (15 minutes in ms)
    readonly property real homeGracePeriodMs: 15 * 60 * 1000

    // Heartbeat ticker to refresh home list when grace period expires
    property int ticker: 0
    Timer {
        interval: 15000 // checks every 15s
        running: true
        repeat: true
        onTriggered: {
            root.ticker++;
        }
    }

    // Filtered list specifically for Home tab:
    // Includes: all pending tasks, plus tasks completed within the last 15 minutes!
    readonly property var homeTodos: {
        let dummy = root.ticker;
        let now = Date.now();
        let list = [];
        for (let i = 0; i < root.todos.length; i++) {
            let item = root.todos[i];
            if (!item.completed) {
                list.push(item);
            } else if (item.completedAt && (now - item.completedAt < root.homeGracePeriodMs)) {
                list.push(item);
            }
        }
        return list;
    }

    readonly property int pendingCount: {
        let count = 0;
        for (let i = 0; i < root.todos.length; i++) {
            if (!root.todos[i].completed) count++;
        }
        return count;
    }

    readonly property int completedCount: root.todos.length - pendingCount

    // Add task
    function addTask(taskText, taskTime) {
        let cleanText = (taskText || "").trim();
        if (cleanText === "") return;

        let item = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            text: cleanText,
            time: taskTime && taskTime.trim() !== "" ? taskTime.trim() : "Today",
            completed: false,
            completedAt: 0
        };

        let copy = [item].concat(root.todos);
        root.todos = copy;
        saveTodos();
    }

    // Toggle task completed state
    function toggleTask(id) {
        let now = Date.now();
        let copy = [];
        for (let i = 0; i < root.todos.length; i++) {
            let t = Object.assign({}, root.todos[i]);
            if (t.id === id) {
                t.completed = !t.completed;
                t.completedAt = t.completed ? now : 0;
            }
            copy.push(t);
        }
        root.todos = copy;
        root.ticker++;
        saveTodos();
    }

    // Delete single task
    function deleteTask(id) {
        let copy = [];
        for (let i = 0; i < root.todos.length; i++) {
            if (root.todos[i].id !== id) {
                copy.push(root.todos[i]);
            }
        }
        root.todos = copy;
        root.ticker++;
        saveTodos();
    }

    // Clear all completed tasks
    function clearCompleted() {
        let copy = [];
        for (let i = 0; i < root.todos.length; i++) {
            if (!root.todos[i].completed) {
                copy.push(root.todos[i]);
            }
        }
        root.todos = copy;
        root.ticker++;
        saveTodos();
    }

    // Process to safely write and load local todos
    Process {
        id: saveProc
    }

    Process {
        id: loadProc
        command: ["sh", "-c", "cat ~/.config/notch_todos.json 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let parsed = JSON.parse(txt);
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            root.todos = parsed;
                        }
                    } catch (e) {
                        // Keep fallback
                    }
                }
            }
        }
    }

    function saveTodos() {
        try {
            let jsonStr = JSON.stringify(root.todos);
            saveProc.exec(["sh", "-c", "echo " + JSON.stringify(jsonStr) + " > ~/.config/notch_todos.json 2>/dev/null || true"]);
        } catch (e) {
            // Ignore write errors
        }
    }

    Component.onCompleted: {
        loadProc.running = true;
    }
}
