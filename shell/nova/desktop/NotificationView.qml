// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: center
    property var backend: null
    property var iconResolver: name => ""
    signal settingsRequested()
    spacing: Theme.space.md
    RowLayout {
        Text { text: qsTr("Historial de la sesión"); color: Theme.color.text; font.pixelSize: Theme.font.body; Layout.fillWidth: true }
        NovaButton { text: qsTr("Vaciar"); enabled: !!center.backend; onClicked: center.backend.clear() }
    }
    Text {
        visible: !center.backend
        text: qsTr("Las notificaciones siguen gestionadas por Plasma. Puedes habilitar el servidor de Nova en Preferencias.")
        color: Theme.color.textMuted
        font.pixelSize: Theme.font.body
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.space.md
        model: center.backend ? center.backend.history : []
        ScrollBar.vertical: ScrollBar {}
        delegate: NotificationCard {
            required property var modelData
            entry: modelData
            iconSource: center.iconResolver(modelData.icon)
            width: ListView.view.width
            actions: center.backend.native(entry.id)?.actions || []
            onDismissRequested: center.backend.dismiss(entry.id)
            onActionRequested: index => center.backend.invoke(entry.id, index)
        }
    }
    NovaButton { text: qsTr("Preferencias de notificaciones"); Layout.fillWidth: true; onClicked: center.settingsRequested() }
    Component.onCompleted: if (backend) backend.markRead()
}
