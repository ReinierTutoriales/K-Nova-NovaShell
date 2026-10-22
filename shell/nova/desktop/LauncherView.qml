// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls
import "../services/DesktopPolicy.mjs" as Policy

ColumnLayout {
    id: launcher
    property var applications: []
    property bool loading: false
    property real progress: -1
    property var iconResolver: name => ""
    readonly property var results: Policy.search(applications, search.text)
    signal launchRequested(string id)
    signal pinRequested(string id)
    signal refreshRequested()
    spacing: Theme.space.md
    function focusInitial() { search.forceActiveFocus(); }
    function launchCurrent() {
        if (!results.length) return;
        const index = Math.min(results.length - 1, Math.max(0, grid.currentIndex));
        launchRequested(results[index].id);
    }
    NovaTextField {
        id: search
        objectName: "launcherSearch"
        Layout.fillWidth: true
        placeholderText: qsTr("Buscar aplicaciones…")
        font.pixelSize: Theme.font.title
        color: Theme.color.text
        focus: true
        onTextChanged: grid.currentIndex = 0
        onAccepted: launcher.launchCurrent()
        Keys.onDownPressed: if (launcher.results.length) grid.forceActiveFocus()
        Accessible.name: placeholderText
    }
    RowLayout {
        Text {
            text: launcher.loading ? qsTr("Actualizando aplicaciones…") : qsTr("%1 aplicaciones").arg(launcher.results.length)
            color: Theme.color.textMuted
            font.pixelSize: Theme.font.small
            Layout.fillWidth: true
        }
        IconButton { label: qsTr("Actualizar"); symbol: "arrows"; onClicked: launcher.refreshRequested() }
    }
    NovaProgressBar {
        objectName: "catalogProgress"
        Layout.fillWidth: true
        visible: launcher.loading
        indeterminate: launcher.progress < 0
        value: Math.max(0, launcher.progress)
        Accessible.name: qsTr("Carga del catálogo de aplicaciones")
    }
    GridView {
        id: grid
        objectName: "launcherGrid"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: Theme.metrics.launcherCellWidth
        cellHeight: Theme.metrics.launcherCellHeight
        model: launcher.results
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        highlightFollowsCurrentItem: true
        currentIndex: 0
        ScrollBar.vertical: ScrollBar {}
        delegate: ApplicationTile {
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight
            applicationName: modelData.name
            iconName: modelData.icon
            iconSource: launcher.iconResolver(modelData.icon)
            onClicked: launcher.launchRequested(modelData.id)
            onActiveFocusChanged: if (activeFocus) grid.currentIndex = index
            Keys.onReturnPressed: launcher.launchRequested(modelData.id)
            Menu {
                id: actions
                MenuItem { text: qsTr("Fijar o quitar del dock"); onTriggered: launcher.pinRequested(modelData.id) }
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: actions.popup() }
        }
        Keys.onReturnPressed: launcher.launchCurrent()
        Keys.onEnterPressed: launcher.launchCurrent()
        Keys.onUpPressed: {
            const columns = Math.max(1, Math.floor(width / cellWidth));
            if (currentIndex < columns) search.forceActiveFocus();
            else currentIndex -= columns;
        }
    }
    Text {
        visible: !launcher.loading && !launcher.results.length
        text: qsTr("No se encontraron aplicaciones")
        color: Theme.color.textMuted
        Layout.alignment: Qt.AlignHCenter
    }
}
