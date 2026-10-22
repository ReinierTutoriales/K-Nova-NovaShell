// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.nova.theme
import qs.nova.controls

ScrollView {
    id: settings
    property var values: ({})
    property bool connected: false
    signal patchRequested(var changes)
    signal wallpaperRequested(string url)
    clip: true
    contentWidth: availableWidth
    function update(key, value) { const patch = {}; patch[key] = value; patchRequested(patch); }
    ColumnLayout {
        width: settings.availableWidth
        spacing: Theme.space.md
        enabled: settings.connected
        Text { text: qsTr("Apariencia"); color: Theme.color.text; font.pixelSize: Theme.font.title }
        NovaButton { text: qsTr("Elegir fondo de pantalla"); symbol: "wallpaper"; Layout.fillWidth: true; onClicked: wallpaper.open() }
        Repeater {
            model: [
                {key: "mode", label: qsTr("Esquema"), choices: ["auto", "light", "dark"]},
                {key: "material", label: qsTr("Material"), choices: ["liquid", "frosted", "solid"]},
                {key: "iconMode", label: qsTr("Iconos"), choices: ["default", "dark", "clear", "tinted"]}
            ]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: modelData.label; color: Theme.color.text; font.pixelSize: Theme.font.body; Layout.fillWidth: true }
                ComboBox {
                    model: modelData.choices
                    currentIndex: Math.max(0, modelData.choices.indexOf(settings.values[modelData.key]))
                    Accessible.name: modelData.label
                    onActivated: settings.update(modelData.key, currentText)
                }
            }
        }
        Text { text: qsTr("Transparencia"); color: Theme.color.text; font.pixelSize: Theme.font.body }
        Slider {
            Layout.fillWidth: true
            from: 0; to: 1
            value: settings.values.transparency ?? 0.5
            Accessible.name: qsTr("Transparencia")
            onPressedChanged: if (!pressed) settings.update("transparency", value)
        }
        Text { text: qsTr("Dock"); color: Theme.color.text; font.pixelSize: Theme.font.title }
        Slider {
            Layout.fillWidth: true
            from: 36; to: 80; stepSize: 1
            value: settings.values.dockIconSize || Theme.icons.application
            Accessible.name: qsTr("Tamaño de los iconos del dock")
            onPressedChanged: if (!pressed) settings.update("dockIconSize", Math.round(value))
        }
        Repeater {
            model: [
                {key: "dockAutoHide", label: qsTr("Ocultar dock automáticamente")},
                {key: "dockMagnify", label: qsTr("Ampliar iconos al pasar el puntero")},
                {key: "showSeconds", label: qsTr("Mostrar segundos en el reloj")},
                {key: "backgroundBlur", label: qsTr("Desenfoque de fondo (si el compositor lo admite)")},
                {key: "reduceMotion", label: qsTr("Reducir movimiento")},
                {key: "reduceTransparency", label: qsTr("Reducir transparencia")},
                {key: "highContrast", label: qsTr("Alto contraste")},
                {key: "notificationServer", label: qsTr("Habilitar servidor de notificaciones Nova")},
                {key: "doNotDisturb", label: qsTr("No molestar en Nova")},
                {key: "clipboardEnabled", label: qsTr("Historial de texto del portapapeles en memoria")}
            ]
            Switch {
                required property var modelData
                text: modelData.label
                checked: settings.values[modelData.key] || false
                Layout.fillWidth: true
                onClicked: settings.update(modelData.key, checked)
            }
        }
        Text {
            text: qsTr("Las preferencias se guardan en tu usuario. El servidor Nova recibe notificaciones cuando Plasma deja libre ese servicio. El portapapeles conserva hasta 30 textos durante esta sesión y solo puede leerlos cuando Wayland permite el acceso.")
            color: Theme.color.textMuted
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
    FileDialog {
        id: wallpaper
        title: qsTr("Elegir fondo de pantalla")
        nameFilters: [qsTr("Imágenes (*.png *.jpg *.jpeg *.webp *.avif *.svg)")]
        onAccepted: settings.wallpaperRequested(selectedFile.toString())
    }
}
