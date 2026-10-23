import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    implicitWidth: 260
    implicitHeight: 160

    property date displayDate: new Date()
    readonly property date today: new Date()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayLabels: ["S", "M", "T", "W", "T", "F", "S"]

    readonly property int currentYear: displayDate.getFullYear()
    readonly property int currentMonth: displayDate.getMonth()

    function prevMonth() {
        let d = new Date(displayDate.getFullYear(), displayDate.getMonth() - 1, 1);
        displayDate = d;
    }

    function nextMonth() {
        let d = new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 1);
        displayDate = d;
    }

    // Days calculation for calendar grid
    readonly property var calendarDays: {
        let year = root.currentYear;
        let month = root.currentMonth;

        let firstDayOfWeek = new Date(year, month, 1).getDay(); // 0 is Sunday
        let daysInCurrentMonth = new Date(year, month + 1, 0).getDate();
        let daysInPrevMonth = new Date(year, month, 0).getDate();

        let days = [];

        // Previous month trailing days
        for (let i = firstDayOfWeek - 1; i >= 0; i--) {
            days.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false,
                hasEvent: false
            });
        }

        // Current month days
        let isSameMonthAsToday = (today.getFullYear() === year && today.getMonth() === month);
        let todayDate = today.getDate();

        for (let d = 1; d <= daysInCurrentMonth; d++) {
            let isTod = isSameMonthAsToday && (d === todayDate);
            // Sample indicator dots like in the reference image
            let hasEv = (d === 10 || d === 19 || d === 23 || d === 28);
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: isTod,
                hasEvent: hasEv
            });
        }

        // Next month trailing days to complete 5 or 6 rows (35 or 42 slots)
        let totalSlots = days.length > 35 ? 42 : 35;
        let nextMonthDay = 1;
        while (days.length < totalSlots) {
            days.push({
                day: nextMonthDay++,
                isCurrentMonth: false,
                isToday: false,
                hasEvent: false
            });
        }

        return days;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Calendar Header: Month + Year and Navigation Arrows
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.monthNames[root.currentMonth] + " " + root.currentYear
                color: Config.mainFg
                font.family: Config.bodyFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: prevM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (prevM.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")
                scale: prevM.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: Config.dimFg
                    font.family: Config.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: prevM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevMonth()
                }
            }

            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: nextM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (nextM.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")
                scale: nextM.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: Config.dimFg
                    font.family: Config.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: nextM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }

        // Day of Week Header row (S M T W T F S)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.dayLabels

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Config.dimFg
                        font.family: Config.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // Days Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: root.calendarDays

                Item {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Today Highlight Circle
                    Rectangle {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        radius: 10
                        color: modelData.isToday ? Config.actBg : "transparent"
                        visible: modelData.isToday
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.day.toString()
                            color: {
                                if (modelData.isToday) return "#ffffff";
                                if (modelData.isCurrentMonth) return Config.mainFg;
                                return Qt.rgba(1, 1, 1, 0.22);
                            }
                            font.family: Config.monoFont
                            font.pixelSize: 11
                            font.weight: modelData.isToday ? Font.Bold : (modelData.isCurrentMonth ? Font.Normal : Font.Light)
                        }

                        // Event indicator dot
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 3
                            height: 3
                            radius: 1.5
                            color: modelData.isToday ? "#ffffff" : Config.actBg
                            visible: modelData.hasEvent && !modelData.isToday
                        }
                    }
                }
            }
        }
    }
}
