// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: history
    property var entries: []
    property bool enabledHistory: false
    signal copyRequested(string text)
    signal clearRequested()
    spacing: Theme.space.md
    Text {
        text: history.enabledHistory ? qsTr("Texto copiado durante esta sesión") : qsTr("Activa el historial en Preferencias para empezar.")
        color: Theme.color.textMuted
        font.pixelSize: Theme.font.body
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.space.sm
        model: history.entries
        ScrollBar.vertical: ScrollBar {}
        delegate: NovaButton {
            required property string modelData
            text: modelData.slice(0, 120).replace(/\n/g, " ")
            width: ListView.view.width
            onClicked: history.copyRequested(modelData)
        }
    }
    NovaButton { text: qsTr("Vaciar historial"); Layout.fillWidth: true; onClicked: history.clearRequested() }
}
