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
        // Lock body
        ShapePath {
            strokeColor: root.name === "lock" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 4; startY: 11
            PathLine { x: 20; y: 11 }
            PathLine { x: 20; y: 21 }
            PathLine { x: 4; y: 21 }
            PathLine { x: 4; y: 11 }
        }
        // Lock shackle
        ShapePath {
            strokeColor: root.name === "lock" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 7; startY: 11
            PathLine { x: 7; y: 7 }
            PathArc { x: 17; y: 7; radiusX: 5; radiusY: 5 }
            PathLine { x: 17; y: 11 }
        }

        // --- SLEEP / MOON ICON ---
        ShapePath {
            strokeColor: root.name === "sleep" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            // Crescent moon contour
            startX: 20; startY: 13
            PathArc { x: 11; y: 4; radiusX: 9; radiusY: 9; direction: PathArc.Counterclockwise }
            PathArc { x: 20; y: 13; radiusX: 7; radiusY: 7; direction: PathArc.Clockwise }
        }

        // --- LOGOUT / EXIT ICON ---
        // Door bracket
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 10; startY: 20
            PathLine { x: 4; y: 20 }
            PathLine { x: 4; y: 4 }
            PathLine { x: 10; y: 4 }
        }
        // Exit arrow stem
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 9; startY: 12
            PathLine { x: 20; y: 12 }
        }
        // Exit arrow head
        ShapePath {
            strokeColor: root.name === "logout" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 15; startY: 7
            PathLine { x: 20; y: 12 }
            PathLine { x: 15; y: 17 }
        }

        // --- RESTART / REBOOT ICON ---
        // Circular arc
        ShapePath {
            strokeColor: root.name === "restart" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 20; startY: 10
            PathArc { x: 12; y: 20; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 5; y: 12; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 10; y: 5; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
        }
        // Restart arrow head
        ShapePath {
            strokeColor: root.name === "restart" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 20; startY: 4
            PathLine { x: 20; y: 10 }
            PathLine { x: 14; y: 10 }
        }

        // --- POWER / SHUTDOWN ICON ---
        // Power vertical line
        ShapePath {
            strokeColor: root.name === "power" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 12; startY: 3
            PathLine { x: 12; y: 11 }
        }
        // Power open circle arc
        ShapePath {
            strokeColor: root.name === "power" ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 17.5; startY: 6.5
            PathArc { x: 12; y: 21; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
            PathArc { x: 6.5; y: 6.5; radiusX: 8; radiusY: 8; direction: PathArc.Clockwise }
        }

        // --- CLOSE / CANCEL ICON ---
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
