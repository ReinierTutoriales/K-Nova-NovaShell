// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.nova.theme
import qs.nova.controls
import qs.nova.icons

// Ajustes con barra lateral de secciones y páginas. Solo presentación: los
// cambios salen por patchRequested hacia settings.patch del daemon.
RowLayout {
    id: settings
    property var values: ({})
    property bool connected: false
    // Estado de integración (opcional; Desktop.qml lo rellena).
    property string daemonVersion: ""
    property bool compositorBlur: false
    property string section: "appearance"
    signal patchRequested(var changes)
    signal wallpaperRequested(string url)
    signal welcomeRequested()
    spacing: Theme.space.lg

    function update(key, value) { const patch = {}; patch[key] = value; patchRequested(patch); }

    readonly property var sections: [
        {id: "appearance", label: qsTr("Apariencia"), symbol: "theme"},
        {id: "desktop", label: qsTr("Escritorio"), symbol: "wallpaper"},
        {id: "dock", label: qsTr("Dock"), symbol: "dock"},
        {id: "bar", label: qsTr("Barra superior"), symbol: "panel"},
        {id: "notifications", label: qsTr("Notificaciones"), symbol: "notification"},
        {id: "accessibility", label: qsTr("Accesibilidad"), symbol: "contrast"},
        {id: "privacy", label: qsTr("Privacidad"), symbol: "lock"},
        {id: "integration", label: qsTr("Estado de integración"), symbol: "check"}
    ]

    // ---- Barra lateral ---------------------------------------------------
    ColumnLayout {
        Layout.preferredWidth: Theme.metrics.sidebarWidth
        Layout.fillHeight: true
        spacing: Theme.space.xxs
        Repeater {
            model: settings.sections
            AbstractButton {
                id: entry
                required property var modelData
                readonly property bool current: settings.section === modelData.id
                Layout.fillWidth: true
                implicitHeight: Theme.metrics.controlHeight
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                onClicked: settings.section = modelData.id
                background: Rectangle {
                    radius: Theme.radius.md
                    color: entry.current ? Theme.color.selection
                        : (entry.hovered ? Theme.color.hover : Theme.color.transparent)
                    border.width: entry.visualFocus ? Theme.metrics.focusWidth : 0
                    border.color: Theme.color.focus
                }
                contentItem: RowLayout {
                    spacing: Theme.space.sm
                    Icon {
                        name: entry.modelData.symbol
                        size: Theme.icons.small
                        tint: entry.current ? Theme.color.accent : Theme.color.text
                        Layout.leftMargin: Theme.space.sm
                    }
                    Text {
                        text: entry.modelData.label
                        color: Theme.color.text
                        font.family: Theme.font.family
                        font.pixelSize: Theme.font.body
                        font.weight: entry.current ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }

    Rectangle {
        Layout.fillHeight: true
        implicitWidth: Theme.space.hairline
        color: Theme.color.border
    }

    // ---- Página ----------------------------------------------------------
    ScrollView {
        id: page
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            width: page.availableWidth
            spacing: Theme.space.md
            enabled: settings.connected

            Text {
                text: settings.sections.find(item => item.id === settings.section)?.label ?? ""
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }

            // Apariencia
            SettingsRow {
                visible: settings.section === "appearance"; label: qsTr("Esquema")
                SegmentedChoice {
                    accessibleName: qsTr("Esquema"); value: settings.values.mode || "auto"
                    options: [{value: "auto", label: qsTr("Sistema")}, {value: "light", label: qsTr("Claro")},
                        {value: "dark", label: qsTr("Oscuro")}]
                    onSelected: choice => settings.update("mode", choice)
                }
            }
            SettingsRow {
                visible: settings.section === "appearance"; label: qsTr("Material")
                SegmentedChoice {
                    accessibleName: qsTr("Material"); value: settings.values.material || "liquid"
                    options: [{value: "liquid", label: qsTr("Cristal")}, {value: "frosted", label: qsTr("Esmerilado")},
                        {value: "solid", label: qsTr("Sólido")}]
                    onSelected: choice => settings.update("material", choice)
                }
            }
            SettingsRow {
                visible: settings.section === "appearance"; label: qsTr("Iconos")
                SegmentedChoice {
                    accessibleName: qsTr("Iconos"); value: settings.values.iconMode || "default"
                    options: [{value: "default", label: qsTr("Color")}, {value: "dark", label: qsTr("Oscuros")},
                        {value: "clear", label: qsTr("Transparentes")}, {value: "tinted", label: qsTr("Teñidos")}]
                    onSelected: choice => settings.update("iconMode", choice)
                }
            }
            SettingsRow {
                visible: settings.section === "appearance"; label: qsTr("Transparencia")
                NovaSlider {
                    Layout.fillWidth: true; from: 0; to: 1
                    value: settings.values.transparency ?? 0.5
                    Accessible.name: qsTr("Transparencia")
                    onPressedChanged: if (!pressed) settings.update("transparency", value)
                }
            }
            NovaSwitch {
                visible: settings.section === "appearance"; Layout.fillWidth: true
                text: qsTr("Desenfoque de fondo")
                description: settings.compositorBlur ? qsTr("Tu compositor lo admite.")
                    : qsTr("Tu compositor no anuncia ext-background-effect-v1; se mantiene una superficie legible.")
                checked: settings.values.backgroundBlur ?? true
                onClicked: settings.update("backgroundBlur", checked)
            }

            // Escritorio
            NovaButton {
                visible: settings.section === "desktop"; Layout.fillWidth: true
                text: qsTr("Elegir fondo de pantalla"); symbol: "wallpaper"
                onClicked: wallpaper.open()
            }
            SettingsToggles {
                visible: settings.section === "desktop"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "desktopWidgets", label: qsTr("Widgets en el escritorio"), fallback: true,
                    description: qsTr("Reloj, calendario y uso del sistema sobre el fondo.")}]
            }
            NovaButton {
                visible: settings.section === "desktop"; Layout.fillWidth: true
                text: qsTr("Ver la bienvenida otra vez"); symbol: "nova"
                onClicked: settings.welcomeRequested()
            }

            // Dock
            SettingsRow {
                visible: settings.section === "dock"; label: qsTr("Tamaño de iconos")
                NovaSlider {
                    Layout.fillWidth: true; from: 36; to: 80; stepSize: 1
                    value: settings.values.dockIconSize || Theme.icons.application
                    Accessible.name: qsTr("Tamaño de los iconos del dock")
                    onPressedChanged: if (!pressed) settings.update("dockIconSize", Math.round(value))
                }
            }
            SettingsToggles {
                visible: settings.section === "dock"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "dockAutoHide", label: qsTr("Ocultar automáticamente")},
                    {key: "dockMagnify", label: qsTr("Ampliar iconos al pasar el puntero"),
                    description: qsTr("Desactivado por defecto, como en macOS: anima en cada pasada del puntero.")}]
            }

            // Barra
            SettingsToggles {
                visible: settings.section === "bar"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "showSeconds", label: qsTr("Mostrar segundos en el reloj"),
                    description: qsTr("Despierta el shell cada segundo; desactivado ahorra energía.")}]
            }

            // Notificaciones
            SettingsToggles {
                visible: settings.section === "notifications"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "notificationServer", label: qsTr("Servidor de notificaciones Nova"),
                        description: qsTr("Recibe notificaciones cuando Plasma deja libre ese servicio.")},
                    {key: "doNotDisturb", label: qsTr("No molestar")}]
            }

            // Accesibilidad
            SettingsToggles {
                visible: settings.section === "accessibility"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "reduceMotion", label: qsTr("Reducir movimiento")},
                    {key: "reduceTransparency", label: qsTr("Reducir transparencia")},
                    {key: "highContrast", label: qsTr("Alto contraste")}]
            }

            // Privacidad
            SettingsToggles {
                visible: settings.section === "privacy"; values: settings.values
                onToggled: (key, value) => settings.update(key, value)
                model: [{key: "clipboardEnabled", label: qsTr("Historial del portapapeles"),
                    description: qsTr("Hasta 30 textos, solo en memoria durante la sesión.")}]
            }

            // Integración
            Repeater {
                model: settings.section !== "integration" ? [] : [
                    {label: qsTr("Servicio nova-platform"), ok: settings.connected,
                        detail: settings.connected ? qsTr("Conectado · %1").arg(settings.daemonVersion) : qsTr("No disponible")},
                    {label: qsTr("Desenfoque del compositor"), ok: settings.compositorBlur,
                        detail: settings.compositorBlur ? qsTr("ext-background-effect-v1 disponible") : qsTr("No anunciado por el compositor")}
                ]
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.space.sm
                    Rectangle {
                        implicitWidth: Theme.metrics.statusSize; implicitHeight: Theme.metrics.statusSize
                        radius: Theme.radius.status
                        color: modelData.ok ? Theme.color.ok : Theme.color.warn
                    }
                    Text { text: modelData.label; color: Theme.color.text; font.pixelSize: Theme.font.body; Layout.fillWidth: true }
                    Text { text: modelData.detail; color: Theme.color.textMuted; font.pixelSize: Theme.font.small }
                }
            }
        }
    }

    FileDialog {
        id: wallpaper
        title: qsTr("Elegir fondo de pantalla")
        nameFilters: [qsTr("Imágenes (*.png *.jpg *.jpeg *.webp *.avif *.svg)")]
        onAccepted: settings.wallpaperRequested(selectedFile.toString())
    }
}
