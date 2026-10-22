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
    screen: output
    visible: ShellState.panel === kind && ShellState.screen === output
    color: Theme.color.transparent
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + Theme.space.md; right: Theme.space.md }
    implicitWidth: Math.min(panelWidth, output.width - Theme.space.xl)
    implicitHeight: Math.min(panelHeight, output.height - Theme.barHeight - Theme.space.xl)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "novashell-panel-" + kind
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blurEnabled ? blurRegion : null
    Region { id: blurRegion; item: surface }
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
                sourceComponent: panel.content
                onLoaded: item.forceActiveFocus()
            }
        }
    }
}
