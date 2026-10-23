import QtQuick
import QtQuick.Layouts
import ".."
import "../core"

Item {
    id: root

    implicitWidth: 42
    implicitHeight: 180

    readonly property bool isVol: OsdService.currentType === "volume"
    readonly property bool isMuted: OsdService.currentMuted
    readonly property real frac: OsdService.currentValue
    readonly property int pct: Math.round(frac * 100)

    // Outer Glass Container
    Rectangle {
        id: container
        anchors.fill: parent
        radius: 21
        color: Qt.rgba(0.06, 0.06, 0.08, 0.88)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        // Canvas provides hardware-level rounded capsule clipping on Wayland
        Canvas {
            id: trackCanvas
            anchors.fill: parent
            anchors.margins: 4

            // Smooth animated level transition
            property real animFrac: 0.0

            Behavior on animFrac {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            onAnimFracChanged: requestPaint()

            Connections {
                target: root
                function onFracChanged() {
                    trackCanvas.animFrac = root.isMuted ? 0.0 : root.frac;
                }
                function onIsMutedChanged() {
                    trackCanvas.animFrac = root.isMuted ? 0.0 : root.frac;
                }
                function onIsVolChanged() {
                    trackCanvas.requestPaint();
                }
            }

            Component.onCompleted: {
                trackCanvas.animFrac = root.isMuted ? 0.0 : root.frac;
                trackCanvas.requestPaint();
            }

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();

                let w = width;
                let h = height;
                let r = w / 2; // Perfect capsule radius

                if (w <= 0 || h <= 0) return;

                // 1. Draw and Clip strictly inside capsule boundary
                ctx.beginPath();
                ctx.moveTo(r, 0);
                ctx.lineTo(w - r, 0);
                ctx.arcTo(w, 0, w, r, r);
                ctx.lineTo(w, h - r);
                ctx.arcTo(w, h, w - r, h, r);
                ctx.lineTo(r, h);
                ctx.arcTo(0, h, 0, h - r, r);
                ctx.lineTo(0, r);
                ctx.arcTo(0, 0, r, 0, r);
                ctx.closePath();

                // Fill background track
                ctx.fillStyle = "rgba(255, 255, 255, 0.08)";
                ctx.fill();

                // Save clip path so fill bar cannot bleed outside under any circumstance
                ctx.clip();

                // 2. Draw Progress Bar from bottom up
                let fillH = h * animFrac;
                if (fillH > 0) {
                    let grad = ctx.createLinearGradient(0, h - fillH, 0, h);
                    if (root.isVol) {
                        if (root.isMuted) {
                            grad.addColorStop(0, "#ff3b30");
                            grad.addColorStop(1, "#dc2626");
                        } else {
                            grad.addColorStop(0, "#38bdf8");
                            grad.addColorStop(1, "#0071e3");
                        }
                    } else {
                        grad.addColorStop(0, "#ffd60a");
                        grad.addColorStop(1, "#ff9f0a");
                    }

                    ctx.fillStyle = grad;
                    // Rect starting from bottom going up, perfectly clipped by outer capsule
                    ctx.fillRect(0, h - fillH, w, fillH);
                }
            }
        }

        // Overlay content: Top Icon & Bottom Percentage
        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 16
            anchors.bottomMargin: 14
            spacing: 0

            // Icon at Top
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: OsdService.currentIcon
                font.family: Config.iconFont
                font.pixelSize: 16
                color: root.isMuted ? Config.danger : Config.mainFg

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Percentage text at Bottom
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.isMuted ? "Mute" : (root.pct + "%")
                font.family: Config.monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
                color: root.isMuted ? Config.danger : Config.mainFg
            }
        }
    }
}
