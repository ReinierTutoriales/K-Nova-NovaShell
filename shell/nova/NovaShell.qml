// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.bar
import qs.nova.theme
import qs.nova.preview

// Raíz del escritorio: crea una barra por pantalla y la retira sola cuando
// una pantalla se desconecta (Variants sigue a Quickshell.screens).
Scope {
    id: root

    Component.onCompleted: {
        Theme.mode = Quickshell.env("NOVA_APPEARANCE") || "auto";
        Theme.material = Quickshell.env("NOVA_MATERIAL") || "frosted";
        Theme.iconMode = Quickshell.env("NOVA_ICON_MODE") || "default";
        Theme.reduceMotion = Quickshell.env("NOVA_REDUCE_MOTION") === "1";
        Theme.reduceTransparency = Quickshell.env("NOVA_REDUCE_TRANSPARENCY") === "1";
        Theme.highContrast = Quickshell.env("NOVA_HIGH_CONTRAST") === "1";
    }

    // El blur lo decide CompositorBlur (detección + NOVA_BACKGROUND_BLUR).
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

        Bar {
            onAppearanceRequested: root.showAppearance()
        }
    }
}
