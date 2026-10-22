// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme
import qs.nova.icons

Button {
    id: root
    required property string label
    property string symbol: "settings"
    property real iconSize: Theme.icons.normal
    implicitWidth: Theme.metrics.touchTarget
    implicitHeight: Theme.metrics.touchTarget
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: label
    ToolTip.visible: hovered
    ToolTip.text: label
    background: ControlFill {
        flat: root.flat
        radius: Theme.radius.sm
        pressed: root.down
        checked: root.checked
        hovered: root.hovered
        focused: root.visualFocus
        opacity: root.enabled ? 1 : Theme.metrics.disabledOpacity
    }
    contentItem: Icon {
        name: root.symbol
        size: root.iconSize
        tint: Theme.color.text
    }
}
