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
        Theme.backgroundBlur = Quickshell.env("NOVA_BACKGROUND_BLUR") === "1";
        Theme.reduceMotion = Quickshell.env("NOVA_REDUCE_MOTION") === "1";
        Theme.reduceTransparency = Quickshell.env("NOVA_REDUCE_TRANSPARENCY") === "1";
        Theme.highContrast = Quickshell.env("NOVA_HIGH_CONTRAST") === "1";
        if (Quickshell.env("NOVA_APPEARANCE_PREVIEW") === "1")
            appearance.visible = true;
    }

    AppearancePreview { id: appearance }

    Variants {
        model: Quickshell.screens

        Bar {
            onAppearanceRequested: {
                appearance.visible = true;
                appearance.raise();
                appearance.requestActivate();
            }
        }
    }
}
