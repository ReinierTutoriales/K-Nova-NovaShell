// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: overview
    property var windows: []
    property var desktops: []
    property string currentDesktop: ""
    property bool available: false
    signal actionRequested(string action, string id)
    spacing: Theme.space.md
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: overview.desktops
            NovaButton {
                required property var modelData
                text: modelData.name || modelData.id
                checkable: true
                checked: modelData.id === overview.currentDesktop
                onClicked: overview.actionRequested("desktop", modelData.id)
            }
        }
    }
    Text {
        visible: !overview.available
        text: qsTr("Esperando la conexión de ventanas con KWin…")
        color: Theme.color.textMuted
        font.pixelSize: Theme.font.body
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.space.sm
        model: overview.windows
        ScrollBar.vertical: ScrollBar {}
        delegate: ContentCard {
            required property var modelData
            width: ListView.view.width
            implicitHeight: row.implicitHeight + Theme.space.md * 2
            RowLayout {
                id: row
                anchors { fill: parent; margins: Theme.space.md }
                NovaButton {
                    text: modelData.title || modelData.appId
                    Layout.fillWidth: true
                    checkable: true
                    checked: modelData.active
                    onClicked: overview.actionRequested("activate", modelData.id)
                }
                IconButton { label: qsTr("Minimizar"); symbol: "dock"; onClicked: overview.actionRequested("minimize", modelData.id) }
                IconButton { label: qsTr("Maximizar"); symbol: "preview"; onClicked: overview.actionRequested("maximize", modelData.id) }
                IconButton { label: qsTr("Cerrar ventana"); symbol: "close"; onClicked: overview.actionRequested("close", modelData.id) }
            }
        }
    }
}
