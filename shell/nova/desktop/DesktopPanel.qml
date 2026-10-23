// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.nova.theme
import qs.nova.controls
import qs.nova.services

PanelWindow {
    id: panel
    required property var output
    required property string kind
    property string title: ""
    property Component content
    property int panelWidth: Theme.metrics.popupWidth
    property int panelHeight: Theme.metrics.popupHeight
    // Centrado en la pantalla (sin anclas de layer-shell) en lugar de bajo la barra.
    property bool centered: false
    screen: output
    readonly property bool opened: ShellState.panel === kind && ShellState.screen === output
    // Estado, no visibilidad efectiva del hijo: con la ventana oculta,
    // reveal.visible es siempre false y el panel no volvía a abrirse.
    visible: panel.opened || reveal.opacity > 0
    color: Theme.color.transparent
    anchors { top: !centered; right: !centered }
    margins { top: centered ? 0 : Theme.barHeight + Theme.space.md; right: centered ? 0 : Theme.space.md }
    // La pantalla puede quedar nula un instante (cambio de VT, reconexión).
    implicitWidth: Math.min(panelWidth, (output?.width ?? panelWidth + Theme.space.xl) - Theme.space.xl)
    implicitHeight: Math.min(panelHeight, (output?.height ?? panelHeight + Theme.barHeight + Theme.space.xl) - Theme.barHeight - Theme.space.xl)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "novashell-panel-" + kind
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: panel.opened ? reveal : emptyInput }
    Item { id: emptyInput; width: 0; height: 0 }
    BackgroundEffect.blurRegion: Theme.blurEnabled ? blurRegion : null
    Region { id: blurRegion; item: surface }
    PanelTransition {
        id: reveal
        anchors.fill: parent
        opened: panel.opened
        GlassSurface {
            id: surface
            anchors.fill: parent
            cornerRadius: Theme.radius.xl
            focus: true
            Keys.onEscapePressed: ShellState.close()
            ColumnLayout {
                anchors { fill: parent; margins: Theme.space.lg }
                spacing: Theme.space.md
                RowLayout {
                    Text { text: panel.title; color: Theme.color.text; font.pixelSize: Theme.font.heading; font.bold: true; Layout.fillWidth: true }
                    IconButton { label: qsTr("Cerrar"); symbol: "close"; onClicked: ShellState.close() }
                }
                Text {
                    text: Platform.lastError
                    visible: text !== ""
                    color: Theme.color.error
                    font.pixelSize: Theme.font.small
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                }
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: panel.visible
                    focus: panel.opened
                    enabled: panel.opened
                    sourceComponent: panel.content
                    onLoaded: {
                        if (!panel.opened) return;
                        if (typeof item.focusInitial === "function") item.focusInitial();
                        else item.forceActiveFocus();
                    }
                }
            }
        }
    }
}
