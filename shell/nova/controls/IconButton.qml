// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme
import qs.nova.icons

Button {
    id: root
    required property string label
    property string symbol: "settings"
    implicitWidth: Theme.metrics.touchTarget
    implicitHeight: Theme.metrics.touchTarget
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: label
    ToolTip.visible: hovered
    ToolTip.text: label
    background: GlassSurface {
        cornerRadius: Theme.radius.sm
        interactive: true
        pressed: root.down
        hovered: root.hovered
        focused: root.visualFocus
        opacity: root.enabled ? 1 : Theme.metrics.disabledOpacity
    }
    contentItem: Icon {
        name: root.symbol
        size: Theme.icons.normal
        tint: Theme.color.text
    }
}
