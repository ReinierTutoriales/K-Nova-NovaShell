// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import qs.nova.theme

TextField {
    id: field
    implicitHeight: Math.max(Theme.metrics.controlHeight, contentHeight + topPadding + bottomPadding)
    implicitWidth: Theme.metrics.controlWidth * 2
    padding: Theme.space.sm
    leftPadding: Theme.space.md
    rightPadding: Theme.space.md
    font.family: Theme.font.family
    font.pixelSize: Theme.font.body
    color: Theme.color.text
    placeholderTextColor: Theme.color.textMuted
    selectionColor: Theme.color.accent
    selectedTextColor: Theme.color.accentText
    hoverEnabled: true
    selectByMouse: true
    opacity: enabled ? 1 : Theme.metrics.disabledOpacity
    background: Rectangle {
        objectName: "novaTextFieldBackground"
        color: Theme.color.surfaceRaised
        radius: Theme.radius.md
        border.width: field.activeFocus ? Theme.metrics.focusWidth : Theme.space.hairline
        border.color: field.activeFocus ? Theme.color.focus : Theme.color.border
    }
}
