// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.theme

QtObject {
    id: preferences
    property var values: ({})
    signal patchRequested(var changes)
    function apply(next) {
        values = next;
        const environment = {mode: "NOVA_APPEARANCE", material: "NOVA_MATERIAL", iconMode: "NOVA_ICON_MODE"};
        for (const key of ["mode", "material", "iconMode", "transparency", "reduceMotion", "reduceTransparency", "highContrast", "backgroundBlur"]) {
            const override = Quickshell.env(environment[key] || "NOVA_" + key.replace(/[A-Z]/g, letter => "_" + letter).toUpperCase());
            Theme[key] = override !== "" ? (typeof next[key] === "boolean" ? override === "1" : override) : next[key];
        }
    }
    function patch(changes) { patchRequested(changes); }
    function togglePin(id) {
        const pins = (values.pins || []).slice();
        const index = pins.indexOf(id);
        if (index >= 0) pins.splice(index, 1);
        else if (pins.length < 24) pins.push(id);
        patch({pins: pins});
    }
}
