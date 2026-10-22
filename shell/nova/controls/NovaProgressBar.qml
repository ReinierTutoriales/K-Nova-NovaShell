// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme

// Operation progress only. Keep CPU/RAM meters separate from task completion.
ProgressBar {
    id: control
    padding: 0
    implicitWidth: Theme.metrics.controlWidth * 2
    implicitHeight: Theme.metrics.sliderTrack
    readonly property bool animating: sweep.running

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
            // LayoutMirroring also applies to the indeterminate sweep.
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
                loops: Animation.Infinite
                running: control.visible && control.enabled && control.indeterminate && !Theme.reduceMotion
            }
        }
    }
}
