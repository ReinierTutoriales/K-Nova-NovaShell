// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

// Bienvenida de primer uso. Apple HIG (Onboarding): breve, opcional y
// práctica. Cada elección se aplica al momento (se aprende haciéndolo), los
// valores por defecto ya sirven, se puede omitir y no vuelve a mostrarse;
// se reabre desde Ajustes → Escritorio. Solo presentación: los cambios salen
// por patchRequested hacia settings.patch del daemon.
ColumnLayout {
    id: welcome
    property var values: ({})
    property bool connected: false
    property int page: 0
    readonly property int lastPage: 3
    signal patchRequested(var changes)
    signal finished()
    spacing: Theme.space.lg

    function update(key, value) { const patch = {}; patch[key] = value; patchRequested(patch); }
    function next() { if (page < lastPage) page += 1; else finished(); }
    function focusInitial() { primary.forceActiveFocus(); }

    Keys.onLeftPressed: if (page > 0 && page < lastPage) page -= 1
    Keys.onRightPressed: if (page < lastPage) page += 1

    onPageChanged: enter.restart()

    StackLayout {
        id: pages
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: welcome.page
        enabled: welcome.connected
        // Desplazamiento como transformación: no compite con el layout.
        transform: Translate { id: shift }

        // 0 · Presentación
        ColumnLayout {
            spacing: Theme.space.md
            Item { Layout.fillHeight: true }
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: Theme.dark ? "../icons/nova-mark-dark.svg" : "../icons/nova-mark-light.svg"
                sourceSize: Qt.size(Theme.icons.preview, Theme.icons.preview)
                Accessible.ignored: true
            }
            WelcomeText {
                text: qsTr("Te damos la bienvenida a NovaShell")
                font.pixelSize: Theme.font.heading
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            WelcomeText {
                text: qsTr("Dos ajustes rápidos y listo. Todo se puede cambiar después en Ajustes.")
                color: Theme.color.textMuted
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.fillHeight: true }
        }

        // 1 · Apariencia
        ColumnLayout {
            spacing: Theme.space.md
            WelcomeText { text: qsTr("Apariencia"); font.pixelSize: Theme.font.title; font.weight: Font.DemiBold }
            WelcomeText { text: qsTr("Se aplica al momento: pruébalo."); color: Theme.color.textMuted }
            SettingsRow {
                label: qsTr("Esquema")
                SegmentedChoice {
                    accessibleName: qsTr("Esquema"); value: welcome.values.mode || "auto"
                    options: [{value: "auto", label: qsTr("Sistema")}, {value: "light", label: qsTr("Claro")},
                        {value: "dark", label: qsTr("Oscuro")}]
                    onSelected: choice => welcome.update("mode", choice)
                }
            }
            SettingsRow {
                label: qsTr("Vidrio")
                GlassIntensity {
                    value: welcome.values.transparency ?? 0.5
                    onCommitted: value => welcome.update("transparency", value)
                }
            }
            SettingsRow {
                label: qsTr("Material")
                SegmentedChoice {
                    accessibleName: qsTr("Material"); value: welcome.values.material || "liquid"
                    options: [{value: "liquid", label: qsTr("Cristal")}, {value: "frosted", label: qsTr("Esmerilado")},
                        {value: "solid", label: qsTr("Sólido")}]
                    onSelected: choice => welcome.update("material", choice)
                }
            }
            Item { Layout.fillHeight: true }
        }

        // 2 · Escritorio y privacidad
        ColumnLayout {
            spacing: Theme.space.md
            WelcomeText { text: qsTr("Escritorio y privacidad"); font.pixelSize: Theme.font.title; font.weight: Font.DemiBold }
            SettingsToggles {
                values: welcome.values
                onToggled: (key, value) => welcome.update(key, value)
                model: [{key: "desktopWidgets", label: qsTr("Widgets en el escritorio"), fallback: true,
                        description: qsTr("Reloj, calendario y uso del sistema sobre el fondo.")},
                    {key: "dockAutoHide", label: qsTr("Ocultar el dock automáticamente")},
                    {key: "clipboardEnabled", label: qsTr("Historial del portapapeles"),
                        description: qsTr("Desactivado por defecto. Hasta 30 textos, solo en memoria.")}]
            }
            Item { Layout.fillHeight: true }
        }

        // 3 · Listo
        ColumnLayout {
            spacing: Theme.space.md
            Item { Layout.fillHeight: true }
            WelcomeText {
                text: qsTr("Todo listo")
                font.pixelSize: Theme.font.heading
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            WelcomeText {
                text: qsTr("Abre las aplicaciones desde la barra o el dock. Para un atajo de teclado, asigna en Ajustes de KDE el comando «qs ipc -c novashell call novashell toggle launcher».")
                color: Theme.color.textMuted
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.fillHeight: true }
        }
    }

    // Entrada de cada página: breve y sin desplazamiento con menos movimiento.
    ParallelAnimation {
        id: enter
        NumberAnimation { target: pages; property: "opacity"; from: 0; to: 1; duration: Theme.motion.normal; easing.type: Easing.OutCubic }
        NumberAnimation { target: shift; property: "x"; from: Theme.reduceMotion ? 0 : Theme.space.lg; to: 0
            duration: Theme.motion.normal; easing.type: Easing.OutCubic }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Row {
            spacing: Theme.space.xs
            Accessible.role: Accessible.Indicator
            Accessible.name: qsTr("Paso %1 de %2").arg(welcome.page + 1).arg(welcome.lastPage + 1)
            Repeater {
                model: welcome.lastPage + 1
                Rectangle {
                    required property int index
                    width: Theme.metrics.statusSize; height: width; radius: width / 2
                    color: index === welcome.page ? Theme.color.accent : Theme.color.sliderTrack
                }
            }
        }
        Item { Layout.fillWidth: true }
        NovaButton {
            visible: welcome.page < welcome.lastPage
            flat: true
            text: qsTr("Omitir")
            onClicked: welcome.finished()
        }
        NovaButton {
            visible: welcome.page > 0 && welcome.page < welcome.lastPage
            text: qsTr("Atrás")
            onClicked: welcome.page -= 1
        }
        NovaButton {
            id: primary
            prominent: true
            text: welcome.page === 0 ? qsTr("Empezar")
                : welcome.page === welcome.lastPage ? qsTr("Usar NovaShell") : qsTr("Continuar")
            onClicked: welcome.next()
            Keys.onReturnPressed: welcome.next()
            Keys.onEnterPressed: welcome.next()
        }
    }
}
