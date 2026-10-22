// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.icons

Button {
    id: root
    property string symbol: ""
    // Acción principal (una por vista): relleno de acento.
    property bool prominent: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: Theme.metrics.controlHeight
    implicitWidth: Math.max(Theme.metrics.controlWidth, Math.ceil(labelMeasure.advanceWidth)
        + (symbol === "" ? 0 : Theme.icons.small + spacing) + leftPadding + rightPadding)
    padding: Theme.space.sm
    leftPadding: padding
    rightPadding: padding
    topPadding: padding
    bottomPadding: padding
    spacing: Theme.space.sm
    Accessible.name: text
    TextMetrics {
        id: labelMeasure
        text: root.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.body
        font.weight: root.prominent ? Font.DemiBold : Font.Normal
    }
    background: ControlFill {
        flat: root.flat
        prominent: root.prominent
        radius: Theme.radius.md
        pressed: root.down
        checked: root.checked
        hovered: root.hovered
        focused: root.visualFocus
        opacity: root.enabled ? 1 : Theme.metrics.disabledOpacity
    }
    contentItem: RowLayout {
        spacing: root.spacing
        Icon {
            visible: root.symbol !== ""
            name: root.symbol
            size: Theme.icons.small
            tint: root.prominent ? Theme.color.accentFillText : Theme.color.text
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: root.text
            color: root.prominent ? Theme.color.accentFillText : Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            font.weight: root.prominent ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
