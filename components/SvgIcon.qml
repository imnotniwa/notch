import QtQuick
import QtQuick.Shapes

Item {
    id: root

    // Supported icon names: "lock", "sleep", "logout", "restart", "power", "close"
    property string name: "lock"
    property color color: "#ffffff"
    property real strokeWidth: 2.0

    implicitWidth: 20
    implicitHeight: 20

    Shape {
        id: shape
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: Math.min(root.width, root.height) / 24.0
        transformOrigin: Item.Center
        layer.enabled: true
        layer.smooth: true

        // --- LOCK ICON ---
        // Lock body (rounded rectangle)
        ShapePath {
            strokeColor: root.name === "lock" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 6; startY: 11
            PathLine { x: 18; y: 11 }
            PathArc { x: 20; y: 13; radiusX: 2; radiusY: 2 }
            PathLine { x: 20; y: 19 }
            PathArc { x: 18; y: 21; radiusX: 2; radiusY: 2 }
            PathLine { x: 6; y: 21 }
            PathArc { x: 4; y: 19; radiusX: 2; radiusY: 2 }
            PathLine { x: 4; y: 13 }
            PathArc { x: 6; y: 11; radiusX: 2; radiusY: 2 }
        }
        // Lock shackle
        ShapePath {
            strokeColor: root.name === "lock" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 7.5; startY: 11
            PathLine { x: 7.5; y: 7.5 }
            PathArc { x: 16.5; y: 7.5; radiusX: 4.5; radiusY: 4.5; direction: PathArc.Clockwise }
            PathLine { x: 16.5; y: 11 }
        }

        // --- SLEEP / MOON ICON ---
        ShapePath {
            strokeColor: root.name === "sleep" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            // Crisp centered crescent moon
            startX: 17; startY: 17.5
            PathArc { x: 10.5; y: 4.5; radiusX: 8.5; radiusY: 8.5; direction: PathArc.Clockwise }
            PathArc { x: 17; y: 17.5; radiusX: 6.8; radiusY: 6.8; direction: PathArc.Counterclockwise }
        }

        // --- LOGOUT / EXIT ICON ---
        // Left door bracket
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 11; startY: 20
            PathLine { x: 5; y: 20 }
            PathArc { x: 4; y: 19; radiusX: 1; radiusY: 1 }
            PathLine { x: 4; y: 5 }
            PathArc { x: 5; y: 4; radiusX: 1; radiusY: 1 }
            PathLine { x: 11; y: 4 }
        }
        // Arrow horizontal stem
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 9; startY: 12
            PathLine { x: 19.5; y: 12 }
        }
        // Arrow chevron head
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 15; startY: 7.5
            PathLine { x: 19.5; y: 12 }
            PathLine { x: 15; y: 16.5 }
        }

        // --- RESTART / REBOOT ICON ---
        // 3/4 circular track
        ShapePath {
            strokeColor: root.name === "restart" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 18.5; startY: 9
            PathArc { x: 12; y: 20; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 4; y: 12; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 12; y: 4; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathLine { x: 18; y: 4 }
        }
        // Restart arrow head
        ShapePath {
            strokeColor: root.name === "restart" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 14; startY: 8.5
            PathLine { x: 18.5; y: 4 }
            PathLine { x: 14; y: 0.5 }
        }

        // --- POWER / SHUTDOWN ICON ---
        // Power vertical switch
        ShapePath {
            strokeColor: root.name === "power" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 12; startY: 3
            PathLine { x: 12; y: 11 }
        }
        // Power circular halo
        ShapePath {
            strokeColor: root.name === "power" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 17.2; startY: 6.8
            PathArc { x: 12; y: 21; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 6.8; y: 6.8; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
        }

        // --- CLOSE ICON ---
        ShapePath {
            strokeColor: root.name === "close" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 6; startY: 6
            PathLine { x: 18; y: 18 }
        }
        ShapePath {
            strokeColor: root.name === "close" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 18; startY: 6
            PathLine { x: 6; y: 18 }
        }
    }
}
