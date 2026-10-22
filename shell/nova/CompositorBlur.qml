// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.services
import qs.nova.theme

// Decide Theme.backgroundBlur sin intervención del usuario:
//   NOVA_BACKGROUND_BLUR=1 -> siempre;  =0 -> nunca;  sin definir -> automático.
// En automático se pide compositor.capabilities al daemon y el blur solo se
// solicita si el compositor anuncia ext-background-effect-v1. Pedirlo a un
// compositor que no lo soporta no tiene efecto visual y obliga a la
// superficie a usar más transparencia de la legible (ver AppearancePolicy).
QtObject {
    id: root

    readonly property string forced: Quickshell.env("NOVA_BACKGROUND_BLUR") || ""
    // Último resultado conocido; se conserva si el daemon se reinicia.
    property bool detected: false

    function apply() {
        Theme.backgroundBlur = forced === "1" || (forced !== "0" && detected);
    }

    function probe() {
        if (forced !== "" || !Platform.connected
            || !Platform.has("compositor.capabilities"))
            return;
        Platform.request("compositor.capabilities", {}, response => {
            if (!response.ok)
                return;
            root.detected = response.result.backgroundEffect === true;
            root.apply();
        });
    }

    // Se sondea al conocer las operaciones del daemon (tras cada conexión).
    readonly property Connections _platform: Connections {
        target: Platform
        function onOperationsChanged() { root.probe() }
    }

    Component.onCompleted: {
        apply();
        probe();
    }
}
