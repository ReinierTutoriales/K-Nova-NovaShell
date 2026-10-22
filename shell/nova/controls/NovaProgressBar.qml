// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme

// Progreso de una operación (no para medidores de CPU/RAM). Sigue Apple HIG
// "Progress indicators":
// - Determinado siempre que se conozca el total; el mismo estilo de barra
//   pasa de indeterminado a determinado, sin cambiar de forma.
// - Ritmo honesto y continuo: el relleno avanza suavizado, no a saltos.
// - Solo existe mientras la operación corre, y no aparece en operaciones
//   que terminan antes de progressDelay: evita el parpadeo en cargas rápidas.
// - Reducir movimiento: sin barrido; un relleno estático y la etiqueta del
//   llamador comunican el estado.
ProgressBar {
    id: control
    // La operación está en curso. Usa esto en lugar de `visible`.
    property bool active: false
    property bool shown: false
    readonly property bool animating: sweep.running

    padding: 0
    implicitWidth: Theme.metrics.controlWidth * 2
    implicitHeight: Theme.metrics.sliderTrack
    visible: shown

    onActiveChanged: if (!active) shown = false
    Timer {
        interval: Theme.motion.progressDelay
        running: control.active && !control.shown
        onTriggered: control.shown = true
    }

    background: Rectangle {
        implicitHeight: Theme.metrics.sliderTrack
        radius: height / 2
        color: Theme.color.sliderTrack
    }
    contentItem: Item {
        id: track
        clip: true
        Rectangle {
            id: fill
            width: control.indeterminate
                ? track.width * (Theme.reduceMotion ? 1 : Theme.metrics.progressSegmentRatio)
                : track.width * control.position
            height: track.height
            radius: height / 2
            color: control.enabled ? Theme.color.accent : Theme.color.textMuted
            opacity: control.indeterminate && Theme.reduceMotion ? Theme.metrics.disabledOpacity : 1
            Behavior on width {
                enabled: !control.indeterminate && !Theme.reduceMotion
                NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic }
            }
            // LayoutMirroring también invierte el barrido indeterminado.
            x: control.indeterminate && !Theme.reduceMotion ? sweepPosition.value
                : control.mirrored ? track.width - width : 0
            QtObject { id: sweepPosition; property real value: 0 }
            NumberAnimation {
                id: sweep
                target: sweepPosition
                property: "value"
                from: control.mirrored ? track.width : -fill.width
                to: control.mirrored ? -fill.width : track.width
                duration: Theme.motion.progressCycle
                easing.type: Easing.InOutSine
                loops: Animation.Infinite
                running: control.visible && control.enabled && control.indeterminate && !Theme.reduceMotion
            }
        }
    }
}
