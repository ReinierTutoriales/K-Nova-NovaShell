// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme

// Selector segmentado: [{value, label}] con la opción activa resaltada.
// Muestra etiquetas traducidas, nunca los valores internos ("liquid"…).
Rectangle {
    id: root
    property var options: []
    property string value: ""
    property string accessibleName: ""
    signal selected(string value)

    implicitHeight: Theme.metrics.controlHeight
    implicitWidth: row.implicitWidth + 2 * Theme.space.xxs
    radius: Theme.radius.md
    color: Theme.color.sliderTrack
    Accessible.role: Accessible.PageTabList
    Accessible.name: accessibleName

    RowLayout {
        id: row
        anchors { fill: parent; margins: Theme.space.xxs }
        spacing: Theme.space.xxs
        Repeater {
            model: root.options
            AbstractButton {
                id: option
                required property var modelData
                readonly property bool current: root.value === modelData.value
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                checkable: true
                checked: current
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: label.implicitWidth + 2 * Theme.space.md
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                onClicked: root.selected(modelData.value)
                background: Rectangle {
                    radius: Theme.radius.sm
                    color: option.current ? Theme.color.surface
                        : (option.hovered ? Theme.color.hover : Theme.color.transparent)
                    border.width: option.visualFocus ? Theme.metrics.focusWidth : 0
                    border.color: Theme.color.focus
                }
                contentItem: Text {
                    id: label
                    text: option.modelData.label
                    color: option.current ? Theme.color.accent : Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                    font.weight: option.current ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
