// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme

// Interruptor con los tokens de Theme: etiqueta a la izquierda, pastilla a
// la derecha (como en los ajustes de macOS/KDE), acento cuando está activo.
Switch {
    id: root
    property string description: ""
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: Theme.space.sm
    implicitHeight: Math.max(Theme.metrics.controlHeight, row.implicitHeight + topPadding + bottomPadding)
    Accessible.name: text
    Accessible.description: description

    indicator: Rectangle {
        x: root.width - width - root.rightPadding
        y: (root.height - height) / 2
        implicitWidth: Theme.metrics.switchWidth
        implicitHeight: Theme.metrics.switchHeight
        radius: height / 2
        color: root.checked ? Theme.color.accent : Theme.color.sliderTrack
        border.width: root.visualFocus ? Theme.metrics.focusWidth : 0
        border.color: Theme.color.focus
        opacity: root.enabled ? 1 : Theme.metrics.disabledOpacity
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }

        Rectangle {
            readonly property int inset: Theme.space.xxs
            x: root.checked ? parent.width - width - inset : inset
            y: inset
            width: parent.height - 2 * inset
            height: width
            radius: width / 2
            color: Theme.color.accentText
            Behavior on x { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
        }
    }

    contentItem: ColumnLayout {
        id: row
        spacing: Theme.space.xxs
        Text {
            text: root.text
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.rightMargin: Theme.metrics.switchWidth + Theme.space.md
        }
        Text {
            visible: root.description !== ""
            text: root.description
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.rightMargin: Theme.metrics.switchWidth + Theme.space.md
        }
    }

    background: Rectangle {
        radius: Theme.radius.md
        color: root.hovered ? Theme.color.hover : Theme.color.transparent
    }
}
