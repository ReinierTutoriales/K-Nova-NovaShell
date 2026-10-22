// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.icons
import qs.nova.controls
import qs.nova.services

// Grupo de estado de la barra (red, volumen, batería) que abre el centro de
// control, como el de macOS. Lee los servicios nativos tipados de Quickshell
// a través de Platform.desktop; no ejecuta nada. Cada indicador se oculta si
// su servicio no existe en el equipo (p. ej. sin batería en un sobremesa).
AbstractButton {
    id: root
    signal activated()
    readonly property var backend: Platform.desktop
    readonly property int volumePercent: Math.round((backend?.volume ?? 0) * 100)
    // UPower en Quickshell da la carga como fracción 0–1; se acepta 0–100 por robustez.
    readonly property real batteryLevel: backend?.batteryPercent ?? 0
    readonly property int batteryPercent: Math.round(batteryLevel > 1 ? batteryLevel : batteryLevel * 100)

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: Theme.metrics.touchTarget
    implicitWidth: row.implicitWidth + 2 * Theme.space.sm
    Accessible.name: qsTr("Centro de control")
    Accessible.description: [
        backend?.wifiAvailable ? (backend.wifiEnabled ? qsTr("Wi-Fi activado") : qsTr("Wi-Fi desactivado")) : "",
        backend?.audioAvailable ? (backend.muted ? qsTr("Sonido silenciado") : qsTr("Volumen %1 %").arg(volumePercent)) : "",
        backend?.batteryPresent ? qsTr("Batería %1 %").arg(batteryPercent) : ""
    ].filter(Boolean).join(", ")
    ToolTip.visible: hovered && Accessible.description !== ""
    ToolTip.text: Accessible.description
    onClicked: activated()

    background: GlassSurface {
        cornerRadius: Theme.radius.sm
        interactive: true
        pressed: root.down
        hovered: root.hovered
        focused: root.visualFocus
        opacity: root.hovered || root.down || root.visualFocus ? 1 : 0
    }

    contentItem: Item {
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Theme.space.sm
            Icon {
                visible: root.backend?.wifiAvailable ?? false
                name: "wifi"
                size: Theme.icons.small
                tint: root.backend?.wifiEnabled ? Theme.color.text : Theme.color.textMuted
            }
            Icon {
                visible: root.backend?.bluetoothAvailable ?? false
                name: "bluetooth"
                size: Theme.icons.small
                tint: root.backend?.bluetoothEnabled ? Theme.color.text : Theme.color.textMuted
            }
            Icon {
                name: "volume"
                size: Theme.icons.small
                tint: root.backend?.audioAvailable && !root.backend.muted ? Theme.color.text : Theme.color.textMuted
            }
            RowLayout {
                visible: root.backend?.batteryPresent ?? false
                spacing: Theme.space.xxs
                Icon {
                    name: "battery"
                    size: Theme.icons.small
                    tint: root.batteryPercent <= Theme.metrics.batteryLow ? Theme.color.error : Theme.color.text
                }
                Text {
                    text: qsTr("%1 %").arg(root.batteryPercent)
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
