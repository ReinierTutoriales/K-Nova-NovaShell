// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.nova.theme

// Barra superior de una pantalla. Solo compone widgets: la lógica vive en
// cada widget y los datos del sistema en qs.nova.services.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "novashell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.color.barBackground

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
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

            Item {
                Layout.fillWidth: true
            }

            PlatformStatus {}

            ClockWidget {}
        }
    }
}
