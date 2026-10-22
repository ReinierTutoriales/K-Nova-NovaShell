// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.controls
import qs.nova.icons
import qs.nova.theme

GlassSurface {
    id: card
    required property var entry
    property var actions: []
    property string iconSource: ""
    signal dismissRequested()
    signal actionRequested(int index)
    implicitHeight: contents.implicitHeight + Theme.space.lg * 2
    ColumnLayout {
        id: contents
        anchors { fill: parent; margins: Theme.space.lg }
        spacing: Theme.space.sm
        RowLayout {
            Artwork { source: card.iconSource; size: Theme.icons.large }
            Text {
                text: card.entry.name
                textFormat: Text.PlainText
                color: Theme.color.textMuted
                font.pixelSize: Theme.font.small
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            IconButton { label: qsTr("Descartar"); symbol: "close"; onClicked: card.dismissRequested() }
        }
        Text { text: card.entry.summary; textFormat: Text.PlainText; color: Theme.color.text; font.pixelSize: Theme.font.title; font.bold: true; wrapMode: Text.Wrap; Layout.fillWidth: true }
        Text { text: card.entry.body; textFormat: Text.PlainText; color: Theme.color.text; font.pixelSize: Theme.font.body; wrapMode: Text.Wrap; maximumLineCount: 5; elide: Text.ElideRight; Layout.fillWidth: true }
        RowLayout {
            Repeater {
                model: card.actions
                NovaButton {
                    required property var modelData
                    required property int index
                    text: modelData.text
                    onClicked: card.actionRequested(index)
                }
            }
        }
    }
}
