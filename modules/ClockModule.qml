import QtQuick
import "../components"
import ".."

Item {
    id: root

    property bool compactMode: false

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property string timeStr: ""
    property string dateStr: ""
    property string compactDateStr: ""

    function updateTime() {
        let now = new Date();
        root.timeStr = Qt.formatTime(now, "hh:mm:ss");
        root.dateStr = Qt.formatDate(now, "dddd, MMMM d, yyyy");
        root.compactDateStr = Qt.formatDate(now, "ddd, MMM d");
    }

    Timer {
        interval: 1000
        repeat: true
        running: Config.notchVisible
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    IslandButton {
        id: btn
        icon: ""
        text: root.timeStr + " • " + root.compactDateStr
        tooltip: root.compactMode ? "" : root.dateStr
        isMonoFont: true
        onClicked: {
            if (root.compactMode) {
                Config.isDeckOpen = true;
            }
        }
    }
}
