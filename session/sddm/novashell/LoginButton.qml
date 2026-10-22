// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import "theme"

// Botón de la pantalla de inicio: relleno plano sobre el fondo (no vidrio
// sobre vidrio) o acento si es la acción principal.
Button {
    id: button
    property string symbol: ""
    property bool prominent: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: Theme.space.sm
    leftPadding: Theme.space.md
    rightPadding: Theme.space.md
    spacing: Theme.space.sm
    implicitHeight: Theme.metrics.controlHeight
    Accessible.name: text

    background: Rectangle {
        radius: height / 2
        color: button.prominent ? (button.down ? Theme.color.accentFillPressed
                : button.hovered ? Theme.color.accentFillHover : Theme.color.accentFill)
            : button.down ? Theme.color.pressed : button.hovered ? Theme.color.hover : Theme.color.transparent
        border.width: button.visualFocus ? Theme.metrics.focusWidth : 0
        border.color: Theme.color.focus
    }
    contentItem: Row {
        spacing: button.spacing
        LoginIcon {
            visible: button.symbol !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: button.symbol || "power"
            size: Theme.icons.small
            tint: button.prominent ? Theme.color.accentText : Theme.color.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.prominent ? Theme.color.accentText : Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            font.weight: button.prominent ? Font.DemiBold : Font.Normal
        }
    }
}
