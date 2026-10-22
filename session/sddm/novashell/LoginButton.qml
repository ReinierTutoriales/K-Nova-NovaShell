// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import "theme"

// Botón de la pantalla de inicio (pie: sesión, teclado, energía).
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

    // En reposo solo símbolo y texto; al pasar el puntero o con foco aparece
    // una cápsula de vidrio transparente (fundido breve).
    background: Item {
        implicitHeight: Theme.metrics.controlHeight
        Rectangle {
            anchors.fill: parent
            visible: button.prominent
            radius: height / 2
            color: button.down ? Theme.color.accentFillPressed
                : button.hovered ? Theme.color.accentFillHover : Theme.color.accentFill
            border.width: button.visualFocus ? Theme.metrics.focusWidth : Theme.space.hairline
            border.color: button.visualFocus ? Theme.color.focus : Theme.color.accentFillRim
        }
        LoginGlass {
            anchors.fill: parent
            visible: !button.prominent && opacity > 0
            hovered: button.hovered
            pressed: button.down
            focused: button.visualFocus
            opacity: button.hovered || button.visualFocus || button.down || button.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
        }
    }
    contentItem: Row {
        spacing: button.spacing
        LoginIcon {
            visible: button.symbol !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: button.symbol || "power"
            size: Theme.icons.small
            tint: button.prominent ? Theme.color.accentFillText : Theme.color.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.prominent ? Theme.color.accentFillText : Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            font.weight: button.prominent ? Font.DemiBold : Font.Normal
        }
    }
}
