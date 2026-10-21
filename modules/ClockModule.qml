import QtQuick
import "../components"
import ".."

Item {
    id: root

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    property string timeStr: ""
    property string dateStr: ""

    function updateTime() {
        let now = new Date();
        root.timeStr = Qt.formatTime(now, "hh:mm:ss");
        root.dateStr = Qt.formatDate(now, "dddd, MMMM d, yyyy");
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
        icon: ""
        text: root.timeStr
        tooltip: root.dateStr
        isMonoFont: true
    }
}
