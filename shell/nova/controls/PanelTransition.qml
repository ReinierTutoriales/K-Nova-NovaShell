// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Transform-only transition: no offscreen layer or continuously running timer.
FocusScope {
    id: transition
    property bool opened: false
    readonly property bool animating: fade.running || resize.running
    visible: opened || opacity > 0
    enabled: opened
    opacity: opened ? 1 : 0
    scale: opened ? 1 : Theme.metrics.panelClosedScale
    transformOrigin: Item.TopRight
    Behavior on opacity {
        enabled: !Theme.reduceMotion
        NumberAnimation { id: fade; duration: Theme.motion.normal; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        enabled: !Theme.reduceMotion
        NumberAnimation { id: resize; duration: Theme.motion.normal; easing.type: Easing.OutCubic }
    }
}
