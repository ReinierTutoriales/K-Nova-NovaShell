// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import qs.nova.bar
import qs.nova.theme
import qs.nova.preview
import qs.nova.desktop
import qs.nova.services

// Raíz del escritorio: crea una barra por pantalla y la retira sola cuando
// una pantalla se desconecta (Variants sigue a Quickshell.screens).
Scope {
    id: root

    Component.onCompleted: {
        Theme.mode = Quickshell.env("NOVA_APPEARANCE") || "auto";
        Theme.material = Quickshell.env("NOVA_MATERIAL") || "liquid";
        Theme.iconMode = Quickshell.env("NOVA_ICON_MODE") || "default";
        Theme.reduceMotion = Quickshell.env("NOVA_REDUCE_MOTION") === "1";
        Theme.reduceTransparency = Quickshell.env("NOVA_REDUCE_TRANSPARENCY") === "1";
        Theme.highContrast = Quickshell.env("NOVA_HIGH_CONTRAST") === "1";
    }

    // Soporte de blur del compositor (Theme.compositorBlur); la preferencia
    // del usuario la aplica PreferencesBridge (Theme.backgroundBlur).
    CompositorBlur {}

    // La ventana de apariencia no existe hasta que se pide: en reposo no
    // ocupa ni un QQuickWindow ni delegados de iconos. Al cerrarla se destruye.
    LazyLoader {
        id: appearance
        active: Quickshell.env("NOVA_APPEARANCE_PREVIEW") === "1"

        AppearancePreview {
            visible: true
            onVisibleChanged: {
                if (!visible)
                    appearance.active = false;
            }
            Component.onCompleted: requestActivate()
        }
    }

    // IPC propia de Quickshell para atajos de teclado (Ajustes de KDE →
    // Atajos → comando `qs ipc call novashell toggle launcher`, etc.).
    // Solo abre paneles conocidos; no ejecuta nada del sistema.
    IpcHandler {
        target: "novashell"
        // Sin propiedades: IpcHandler expone las suyas por IPC y un array no cabe.
        function toggle(panel: string): string {
            const panels = ["launcher", "controls", "notifications", "settings",
                "overview", "clipboard", "widgets", "welcome"];
            if (panels.indexOf(panel) < 0)
                return "panel desconocido: " + panel;
            ShellState.toggle(panel, ShellState.screen || Quickshell.screens[0]);
            return ShellState.panel;
        }
        function close(): void { ShellState.close(); }
        function appearance(): void { root.showAppearance(); }
    }

    // Bienvenida: se abre sola una vez, cuando llegan las preferencias del
    // daemon y no consta completada. Cerrarla de cualquier modo (terminar,
    // Omitir, Esc o la X) la marca como vista: no vuelve a aparecer sola.
    Connections {
        target: Platform.preferences
        property bool offered: false
        function onValuesChanged() {
            const values = Platform.preferences.values;
            if (offered || values.welcomeCompleted !== false) return;
            offered = true;
            if (ShellState.panel === "") ShellState.toggle("welcome", Quickshell.screens[0]);
        }
    }
    Connections {
        target: ShellState
        property string previous: ""
        function onPanelChanged() {
            if (previous === "welcome" && ShellState.panel !== "welcome"
                    && Platform.preferences.values.welcomeCompleted === false)
                Platform.preferences.patch({welcomeCompleted: true});
            previous = ShellState.panel;
        }
    }

    function showAppearance() {
        if (appearance.active && appearance.item) {
            appearance.item.raise();
            appearance.item.requestActivate();
        } else {
            appearance.active = true;
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: outputScope
            required property var modelData
            Desktop { output: outputScope.modelData }
            Bar {
                modelData: outputScope.modelData
                onAppearanceRequested: root.showAppearance()
            }
        }
    }
}
