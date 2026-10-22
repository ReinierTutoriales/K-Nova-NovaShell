// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.services
import qs.nova.theme

// Fija Theme.compositorBlur: si el compositor admite el blur que usa
// Quickshell (ext-background-effect-v1). La preferencia del usuario
// (Theme.backgroundBlur) es independiente; el blur exige ambas.
//   NOVA_COMPOSITOR_BLUR=1 -> se da por soportado;  =0 -> se da por no
//   soportado;  sin definir -> se pregunta al daemon (compositor.capabilities).
QtObject {
    id: root

    readonly property string forced: Quickshell.env("NOVA_COMPOSITOR_BLUR") || ""
    // Último resultado conocido; se conserva si el daemon se reinicia.
    property bool detected: false

    function apply() {
        Theme.compositorBlur = forced === "1" || (forced !== "0" && detected);
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
