import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"
import ".."

Item {
    id: root

    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: {
        closeModal();
    }

    function closeModal() {
        Config.todoModalVisible = false;
    }

    function submitTask() {
        let txt = taskTextInput.text.trim();
        if (txt !== "") {
            let due = timeInput.text.trim();
            TodoService.addTask(txt, due);
            taskTextInput.text = "";
            timeInput.text = "";
            closeModal();
        }
    }

    Component.onCompleted: {
        root.forceActiveFocus();
        modalCard.scale = 0.92;
        modalCard.opacity = 0;
        openAnim.start();
        taskTextInput.forceActiveFocus();
    }

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus();
            modalCard.scale = 0.92;
            modalCard.opacity = 0;
            openAnim.start();
            taskTextInput.text = "";
            timeInput.text = "";
            taskTextInput.forceActiveFocus();
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: modalCard
            property: "scale"
            to: 1.0
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }
        NumberAnimation {
            target: modalCard
            property: "opacity"
            to: 1.0
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    // Fullscreen Dimmed Backdrop (Apple Scrim)
    Rectangle {
        anchors.fill: parent
        color: "#80000000"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.closeModal();
            }
        }
    }

    // Centered Apple Dialog
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: 380
        implicitHeight: contentCol.implicitHeight + 36
        radius: 20
        color: Config.islandBg
        border.color: Config.islandBorder
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "New Item"
                    color: Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: closeM.pressed ? Qt.rgba(1, 1, 1, 0.20) : (closeM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Config.mainFg
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: closeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeModal()
                    }
                }
            }

            // Task Title Input
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 12
                color: taskTextInput.activeFocus ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.color: taskTextInput.activeFocus ? Config.actBg : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1

                TextInput {
                    id: taskTextInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 13
                    selectByMouse: true
                    clip: true
                    activeFocusOnTab: false

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Title (e.g. Design review)"
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 13
                        visible: taskTextInput.text === "" && !taskTextInput.activeFocus
                    }

                    // Press Enter to submit immediately if title is present
                    onAccepted: {
                        root.submitTask();
                    }

                    Keys.onTabPressed: (event) => {
                        timeInput.forceActiveFocus();
                        event.accepted = true;
                    }

                    Keys.onDownPressed: (event) => {
                        timeInput.forceActiveFocus();
                        event.accepted = true;
                    }

                    Keys.onEscapePressed: (event) => {
                        root.closeModal();
                        event.accepted = true;
                    }
                }
            }

            // Time / Subtitle Input
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: timeInput.activeFocus ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                border.color: timeInput.activeFocus ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                TextInput {
                    id: timeInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Config.mainFg
                    font.family: Config.bodyFont
                    font.pixelSize: 12
                    selectByMouse: true
                    clip: true
                    activeFocusOnTab: false

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Time or note (e.g. 3:00 PM · Studio 2)"
                        color: Config.dimFg
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        visible: timeInput.text === "" && !timeInput.activeFocus
                    }

                    onAccepted: {
                        root.submitTask();
                    }

                    Keys.onTabPressed: (event) => {
                        taskTextInput.forceActiveFocus();
                        event.accepted = true;
                    }

                    Keys.onBacktabPressed: (event) => {
                        taskTextInput.forceActiveFocus();
                        event.accepted = true;
                    }

                    Keys.onUpPressed: (event) => {
                        taskTextInput.forceActiveFocus();
                        event.accepted = true;
                    }

                    Keys.onEscapePressed: (event) => {
                        root.closeModal();
                        event.accepted = true;
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 74
                    implicitHeight: 32
                    radius: 16
                    color: cancelM.pressed ? Qt.rgba(1, 1, 1, 0.18) : (cancelM.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05))
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Config.mainFg
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: cancelM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeModal()
                    }
                }

                Rectangle {
                    implicitWidth: 90
                    implicitHeight: 32
                    radius: 16
                    color: submitM.pressed ? Qt.darker(Config.actBg, 1.2) : (submitM.containsMouse ? Qt.lighter(Config.actBg, 1.1) : Config.actBg)

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: "#ffffff"
                        font.family: Config.bodyFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: submitM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitTask()
                    }
                }
            }
        }
    }
}
