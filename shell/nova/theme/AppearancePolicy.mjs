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

// Contraste WCAG entre dos colores "#rrggbb".
function channel(value) {
    const c = value / 255;
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}
function luminance(hex) {
    const n = parseInt(hex.slice(1, 7), 16);
    return 0.2126 * channel((n >> 16) & 255) + 0.7152 * channel((n >> 8) & 255) + 0.0722 * channel(n & 255);
}
export function contrast(a, b) {
    const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
    return (x + 0.05) / (y + 0.05);
}
// Relleno para un acento con texto blanco encima: lo oscurece lo justo para
// llegar a 4,5:1 (WCAG AA), sea cual sea el acento que elija el usuario.
// `extra` oscurece más para hover/pulsado sin perder contraste.
export function readableFill(accent, extra = 0) {
    const value = /^#[0-9a-f]{6}$/i.test(String(accent)) ? String(accent) : "#3478f6";
    const n = parseInt(value.slice(1), 16);
    let rgb = [(n >> 16) & 255, (n >> 8) & 255, n & 255];
    const hex = () => "#" + rgb.map(c => Math.round(c).toString(16).padStart(2, "0")).join("");
    for (let step = 0; step < 24 && contrast(hex(), "#ffffff") < 4.5; ++step)
        rgb = rgb.map(c => c * 0.94);
    rgb = rgb.map(c => c * (1 - extra));
    return hex();
}
