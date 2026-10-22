// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.nova.theme
import qs.nova.icons
import qs.nova.controls
import qs.nova.services
import "../services/DesktopPolicy.mjs" as Policy

PanelWindow {
    id: dock
    required property var output
    property bool held: false
    property var activeMenu: null
    readonly property bool revealed: !Platform.preferences.values.dockAutoHide || held || !!activeMenu || ShellState.panel !== ""
    readonly property int iconSize: Platform.preferences.values.dockIconSize || Theme.icons.application
    screen: output
    anchors.bottom: true
    implicitWidth: Math.min(output.width - Theme.space.xl, row.implicitWidth + Theme.space.xl * 2)
    implicitHeight: Theme.metrics.dockHeight + Math.max(0, iconSize - Theme.icons.application)
    color: Theme.color.transparent
    exclusionMode: Platform.preferences.values.dockAutoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: Platform.preferences.values.dockAutoHide ? 0 : iconSize + Theme.space.xl
    WlrLayershell.namespace: "novashell-dock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: dock.revealed ? inputArea : handle }
    BackgroundEffect.blurRegion: Theme.blurEnabled && revealed ? blurRegion : null
    Region { id: blurRegion; item: card }
    Item { id: inputArea; anchors.fill: parent }
    Item { id: handle; anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: Theme.space.xs }
    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) { dock.held = true; hideTimer.stop(); }
            else hideTimer.restart();
        }
    }
    Timer { id: hideTimer; interval: Theme.motion.slow + Theme.motion.normal; onTriggered: dock.held = false }
    GlassSurface {
        id: card
        width: parent.width
        height: dock.iconSize + Theme.space.xl
        y: dock.revealed ? dock.height - height - Theme.space.sm : dock.height + Theme.space.sm
        cornerRadius: Theme.radius.xl
        Behavior on y { NumberAnimation { duration: Theme.motion.normal; easing.type: Easing.OutCubic } }
        Flickable {
            anchors { fill: parent; leftMargin: Theme.space.lg; rightMargin: Theme.space.lg }
            contentWidth: row.implicitWidth
            contentHeight: height
            clip: false
            boundsBehavior: Flickable.StopAtBounds
            RowLayout {
                id: row
                height: parent.height
                spacing: Theme.space.lg
                IconButton { label: qsTr("Aplicaciones"); symbol: "grid"; onClicked: { Platform.reloadApplications(); ShellState.toggle("launcher", dock.output); } }
                Repeater {
                    model: Platform.dockItems
                    ApplicationTile {
                        id: app
                        required property var modelData
                        applicationName: modelData.name
                        iconName: modelData.icon
                        iconSource: Platform.iconUrl(modelData.icon)
                        showLabel: false
                        running: modelData.windows.length > 0
                        iconSize: dock.iconSize
                        implicitWidth: dock.iconSize
                        implicitHeight: dock.iconSize + Theme.space.sm
                        scale: hover.hovered && Platform.preferences.values.dockMagnify && !Theme.reduceMotion
                            ? 1 + (Theme.metrics.dockMaxScale - 1) * Policy.influenceAt(hover.point.position.x - app.mapToItem(dock.contentItem, app.width / 2, 0).x, dock.iconSize * 2)
                            : 1
                        transformOrigin: Item.Bottom
                        Behavior on scale { NumberAnimation { duration: Theme.motion.fast } }
                        onClicked: Platform.activateApplication(modelData)
                        Menu {
                            id: menu
                            MenuItem { text: qsTr("Abrir nueva instancia"); onTriggered: Platform.launch(modelData.id) }
                            MenuItem { text: modelData.pinned ? qsTr("Quitar del dock") : qsTr("Fijar en el dock"); onTriggered: Platform.preferences.togglePin(modelData.id) }
                            MenuItem { text: qsTr("Minimizar ventanas"); enabled: modelData.windows.length > 0; onTriggered: Platform.windowAction("minimize", modelData.windows.map(window => window.id)) }
                            MenuItem { text: qsTr("Cerrar ventanas"); enabled: modelData.windows.length > 0; onTriggered: Platform.windowAction("close", modelData.windows.map(window => window.id)) }
                            onAboutToShow: {
                                if (dock.activeMenu && dock.activeMenu !== menu) dock.activeMenu.close();
                                dock.activeMenu = menu;
                            }
                            onClosed: { if (dock.activeMenu === menu) dock.activeMenu = null; hideTimer.restart(); }
                        }
                        TapHandler { acceptedButtons: Qt.RightButton; onTapped: menu.popup() }
                    }
                }
                Rectangle { implicitWidth: Theme.space.hairline; implicitHeight: Theme.icons.application; color: Theme.color.border }
                IconButton { label: qsTr("Ventanas y escritorios"); symbol: "preview"; onClicked: ShellState.toggle("overview", dock.output) }
                IconButton { label: qsTr("Preferencias"); symbol: "settings"; onClicked: ShellState.toggle("settings", dock.output) }
            }
        }
    }
}
