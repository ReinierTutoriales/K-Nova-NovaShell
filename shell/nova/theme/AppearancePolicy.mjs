// SPDX-License-Identifier: GPL-3.0-or-later
export const modes = Object.freeze(["auto", "light", "dark"]);
export const materials = Object.freeze(["liquid", "frosted", "solid"]);
export const iconModes = Object.freeze(["default", "dark", "clear", "tinted"]);
export function choice(value, allowed, fallback) {
    return allowed.includes(value) ? value : fallback;
}
export function unit(value, fallback = 0.5) {
    return typeof value === "number" && Number.isFinite(value)
        ? Math.min(1, Math.max(0, value)) : fallback;
}
export function surfaceAlpha(material, amount, opaque, blur) {
    if (opaque || material === "solid")
        return 1;
    // Translucency is not blur: unknown compositors retain a readable fill.
    const base = material === "liquid" ? 0.58 : 0.76;
    return Math.max(blur ? 0.38 : 0.88, base + (1 - unit(amount)) * 0.20);
}
