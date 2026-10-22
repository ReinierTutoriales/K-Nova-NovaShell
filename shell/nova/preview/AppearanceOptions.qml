// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: root
    spacing: Theme.space.md
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: [
                { value: "auto", label: qsTr("Sistema") },
                { value: "light", label: qsTr("Claro") },
                { value: "dark", label: qsTr("Oscuro") }
            ]
            NovaButton {
                required property var modelData
                text: modelData.label
                objectName: "appearance-mode-" + modelData.value
                checkable: true
                checked: Theme.effectiveMode === modelData.value
                onClicked: Theme.mode = modelData.value
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: [
                { value: "liquid", label: qsTr("Cristal") },
                { value: "frosted", label: qsTr("Esmerilado") },
                { value: "solid", label: qsTr("Sólido") }
            ]
            NovaButton {
                required property var modelData
                text: modelData.label
                objectName: "appearance-material-" + modelData.value
                checkable: true
                checked: Theme.effectiveMaterial === modelData.value
                onClicked: Theme.material = modelData.value
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: [
                { value: "default", label: qsTr("Color") },
                { value: "dark", label: qsTr("Iconos oscuros") },
                { value: "clear", label: qsTr("Transparentes") },
                { value: "tinted", label: qsTr("Teñidos") }
            ]
            NovaButton {
                required property var modelData
                text: modelData.label
                objectName: "appearance-icons-" + modelData.value
                checkable: true
                checked: Theme.effectiveIconMode === modelData.value
                onClicked: Theme.iconMode = modelData.value
            }
        }
    }
    Text {
        text: qsTr("Transparencia")
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.body
    }
    NovaSlider {
        Layout.fillWidth: true
        from: 0
        to: 1
        value: Theme.glassAmount
        enabled: !Theme.opaque && Theme.effectiveMaterial !== "solid"
        Accessible.name: qsTr("Transparencia")
        onMoved: Theme.transparency = value
    }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        NovaButton {
            text: qsTr("Reducir movimiento")
            objectName: "appearance-reduce-motion"
            checkable: true
            checked: Theme.reduceMotion
            onClicked: Theme.reduceMotion = !Theme.reduceMotion
        }
        NovaButton {
            text: qsTr("Reducir transparencia")
            objectName: "appearance-reduce-transparency"
            checkable: true
            checked: Theme.reduceTransparency
            onClicked: Theme.reduceTransparency = !Theme.reduceTransparency
        }
        NovaButton {
            text: qsTr("Alto contraste")
            objectName: "appearance-high-contrast"
            checkable: true
            checked: Theme.highContrast
            onClicked: Theme.highContrast = !Theme.highContrast
        }
    }
}
