// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.nova.theme
import qs.nova.controls
import qs.nova.services
import qs.nova.desktop

// Barra superior de una pantalla. Solo compone widgets: la lógica vive en
// cada widget y los datos del sistema en qs.nova.services.
PanelWindow {
    id: bar

    required property var modelData
    signal appearanceRequested()
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.color.transparent
    BackgroundEffect.blurRegion: Theme.blurEnabled ? blurRegion : null
    Region { id: blurRegion; item: bar.contentItem }

    WlrLayershell.namespace: "novashell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    GlassSurface {
        anchors.fill: parent
        cornerRadius: Theme.radius.none

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: Theme.space.hairline
            color: Theme.color.border
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Theme.space.md
                rightMargin: Theme.space.md
            }
            spacing: Theme.space.md

            Text {
                text: "NovaShell"
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.body
                font.weight: Font.DemiBold
            }

            IconButton {
                label: qsTr("Aplicaciones")
                symbol: "grid"
                onClicked: { Platform.reloadApplications(); ShellState.toggle("launcher", bar.screen); }
            }
            IconButton {
                label: qsTr("Apariencia")
                symbol: "theme"
                onClicked: bar.appearanceRequested()
            }

            Item {
                Layout.fillWidth: true
            }

            PlatformStatus {}
            TrayRow { window: bar }
            IconButton { label: qsTr("Centro de control"); symbol: "volume"; onClicked: ShellState.toggle("controls", bar.screen) }
            IconButton { label: qsTr("Portapapeles"); symbol: "panel"; onClicked: ShellState.toggle("clipboard", bar.screen) }
            IconButton { label: qsTr("Notificaciones"); symbol: "notification"; onClicked: ShellState.toggle("notifications", bar.screen) }
            IconButton { label: qsTr("Hoy"); symbol: "calendar"; onClicked: ShellState.toggle("widgets", bar.screen) }

            ClockWidget {}
        }
    }
}
