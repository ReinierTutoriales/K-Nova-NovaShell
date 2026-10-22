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
    property int loadedCount: 0
    property int totalCount: 0
    property var iconResolver: name => ""
    // Índice normalizado una sola vez por catálogo; cada pulsación solo
    // puntúa y ordena (instantáneo incluso con miles de aplicaciones).
    readonly property var searchIndex: Policy.searchIndex(applications)
    readonly property var results: Policy.search(applications, search.text, searchIndex)
    signal launchRequested(string id)
    signal pinRequested(string id)
    signal refreshRequested()
    spacing: Theme.space.md
    function focusInitial() { search.forceActiveFocus(); }
    // Un único menú contextual para toda la rejilla (no uno por celda).
    function showActions(id) { actions.target = id; actions.popup(); }
    Menu {
        id: actions
        property string target: ""
        MenuItem { text: qsTr("Fijar o quitar del dock"); onTriggered: launcher.pinRequested(actions.target) }
    }
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
        // Esc borra la búsqueda; con el campo vacío, cierra el panel (como Spotlight).
        Keys.onEscapePressed: event => {
            if (text.length) { clear(); event.accepted = true; }
            else event.accepted = false;
        }
        Accessible.name: placeholderText
    }
    RowLayout {
        Text {
            // Etiqueta concreta (Apple HIG): qué se hace y cuánto falta.
            text: !launcher.loading ? qsTr("%1 aplicaciones").arg(launcher.results.length)
                : launcher.totalCount > 0 ? qsTr("Leyendo aplicaciones instaladas: %1 de %2").arg(launcher.loadedCount).arg(launcher.totalCount)
                : qsTr("Buscando aplicaciones instaladas…")
            color: Theme.color.textMuted
            font.pixelSize: Theme.font.small
            Layout.fillWidth: true
        }
        IconButton { label: qsTr("Actualizar"); symbol: "arrows"; onClicked: launcher.refreshRequested() }
    }
    NovaProgressBar {
        objectName: "catalogProgress"
        Layout.fillWidth: true
        active: launcher.loading
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
        // Cada pulsación cambia el modelo: reutilizar celdas evita crear y
        // destruir decenas de delegados (y recargar sus iconos) por tecla.
        reuseItems: true
        keyNavigationEnabled: true
        highlightFollowsCurrentItem: true
        currentIndex: 0
        // El primer resultado se ve seleccionado mientras se escribe: Intro lo
        // abre. El resaltado se desliza breve entre celdas (sin él con menos
        // movimiento) y no anima nada más por pulsación.
        highlightMoveDuration: Theme.motion.fast
        highlight: Rectangle {
            visible: launcher.results.length > 0
            radius: Theme.radius.lg
            color: Theme.color.selection
        }
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
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: launcher.showActions(modelData.id) }
        }
        Keys.onReturnPressed: launcher.launchCurrent()
        Keys.onEnterPressed: launcher.launchCurrent()
        // Escribir con la rejilla enfocada sigue buscando.
        Keys.onPressed: event => {
            if (event.text.length === 1 && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                search.forceActiveFocus();
                search.insert(search.cursorPosition, event.text);
                event.accepted = true;
            }
        }
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
