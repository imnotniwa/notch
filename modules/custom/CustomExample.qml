import QtQuick
import "../../components"
import "../../core"
import "../.."

Item {
    id: root

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    IslandButton {
        id: btn
        icon: "󰄛"
        tooltip: "Custom Module Example"
        onClicked: {
            Config.run("notify-send 'Notch' 'Custom plug-and-play module working!'");
        }
    }
}
