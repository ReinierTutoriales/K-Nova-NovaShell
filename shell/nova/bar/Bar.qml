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
        border.width: 0

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
                iconSize: Theme.icons.bar
                flat: true
                label: qsTr("Buscar y abrir aplicaciones")
                symbol: "launcher"
                onClicked: { Platform.reloadApplications(); ShellState.toggle("launcher", bar.screen); }
            }
            IconButton {
                iconSize: Theme.icons.bar
                flat: true
                label: qsTr("Apariencia")
                symbol: "theme"
                onClicked: bar.appearanceRequested()
            }

            Item {
                Layout.fillWidth: true
            }

            PlatformStatus {}
            TrayRow { window: bar }
            StatusIndicators { onActivated: ShellState.toggle("controls", bar.screen) }
            IconButton { flat: true; iconSize: Theme.icons.bar; label: qsTr("Portapapeles"); symbol: "panel"; onClicked: ShellState.toggle("clipboard", bar.screen) }
            IconButton { flat: true; iconSize: Theme.icons.bar; label: qsTr("Notificaciones"); symbol: "notification"; onClicked: ShellState.toggle("notifications", bar.screen) }
            ClockWidget { onActivated: ShellState.toggle("widgets", bar.screen) }
        }
    }
}
