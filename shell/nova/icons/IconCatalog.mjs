// SPDX-License-Identifier: GPL-3.0-only
// Adapted symbol paths; see THIRD_PARTY_NOTICES.md. Modified 2026-10-22.
// New semantic roles, application artwork and bounded SVG generation.
import * as Corners from "../theme/CornerGeometry.mjs";

export const symbols = Object.freeze({

        check: "M5 12l5 5L20 7",
        close: "M6 6l12 12M18 6L6 18",
        chevron: "M6 9l6 6 6-6",
        preview: "M7 17L17 7M8 7h9v9",
        theme: "M12 3l9 9-9 9-9-9zM8 12l4-4 4 4-4 4z",
        wallpaper: "M3 4h18v16H3zM3 16l5-5 4 4 3-3 6 5M16 8h.01",
        panel: "M3 5h18v14H3zM3 9h18M7 9v10",
        dock: "M3 13h18v7H3zM7 16v1M12 16v1M17 16v1",
        grid: "M3 3h6v6H3zM15 3h6v6h-6zM3 15h6v6H3zM15 15h6v6h-6z",
        keyboard: "M3 6h18v12H3zM7 10h.01M12 10h.01M17 10h.01M7 14h10",
        settings: "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6L7 7M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4",
        trash: "M3 6h18M8 6V3h8v3M6 6l1 15h10l1-15M10 10v7M14 10v7",
        arrows: "M3 12h18M7 8l-4 4 4 4M17 8l4 4-4 4",
        circle: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8",
        contrast: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M12 3v18M12 7h5M12 11h8M12 15h7",
        waves: "M3 8c3-4 6 4 9 0s6 4 9 0M3 16c3-4 6 4 9 0s6 4 9 0",
        copy: "M8 8h13v13H8zM16 8V3H3v13h5",
        home: "M3 10l9-7 9 7M5 9v12h14V9M10 21v-7h4v7",
        search: "M10 3a7 7 0 1 0 0 14 7 7 0 0 0 0-14M15 15l6 6",
        resize: "M4 10V4h6M20 14v6h-6M4 4l6 6M20 20l-6-6",
        undo: "M8 4L3 9l5 5M3 9h11a6 6 0 0 1 0 12",
        bold: "M6 3h7a4.5 4.5 0 0 1 0 9H6zM6 12h8a4.5 4.5 0 0 1 0 9H6z",
        corners: "M4 12V8a4 4 0 0 1 4-4h4M12 20h4a4 4 0 0 0 4-4v-4",
        shadow: "M4 4h13v13H4zM8 20h12V8",
        minimize: "M4 6h16v12H4zM9 12l3 3 3-3M12 9v6",
        plus: "M12 4v16M4 12h16",
    nova: "M12 2l2.5 6.5L21 11l-6.5 2.5L12 21l-2.5-7.5L3 11l6.5-2.5z",
    application: "M4 4h16v16H4zM4 9h16M9 9v11",
    files: "M3 7V5h7l2 2h9v13H3z",
    browser: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M16 8l-3 6-5 2 3-6z",
    terminal: "M3 4h18v16H3zM6 9l4 3-4 3M13 16h5",
    mail: "M3 5h18v14H3zM3 6l9 7 9-7",
    calendar: "M3 5h18v16H3zM7 3v4M17 3v4M3 10h18M7 14h3M14 14h3M7 18h3",
    calculator: "M5 3h14v18H5zM8 6h8v4H8zM8 14h1M15 14h1M8 18h1M15 18h1",
    music: "M9 17V5l11-2v12M9 17a3 3 0 1 1-3-3h3M20 15a3 3 0 1 1-3-3h3",
    photos: "M3 4h18v16H3zM3 16l5-5 4 4 3-3 6 5M16 8h.01",
    notes: "M5 3h14v18H5zM8 8h8M8 12h8M8 16h5",
    weather: "M8 15a4 4 0 1 1 3-7 5 5 0 1 1 7 7zM15 3V1M20 5l2-2M22 9h2",
    tasks: "M9 5h12M9 12h12M9 19h12M2 5l2 2 3-4M2 12l2 2 3-4M2 19l2 2 3-4",
    monitor: "M3 4h18v13H3zM8 21h8M12 17v4M6 13l3-4 3 3 5-5",
    store: "M4 8h16l1 13H3zM8 8V6a4 4 0 0 1 8 0v2",
    wifi: "M2 8a16 16 0 0 1 20 0M5 12a11 11 0 0 1 14 0M8 16a6 6 0 0 1 8 0M12 20h.01",
    bluetooth: "M12 2v20l6-5L6 7M12 2l6 5L6 17",
    volume: "M3 9h4l5-5v16l-5-5H3zM16 8a6 6 0 0 1 0 8M19 5a10 10 0 0 1 0 14",
    battery: "M2 6h18v12H2zM22 10v4M5 9h10v6H5z",
    brightness: "M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10M12 1v3M12 20v3M1 12h3M20 12h3M4 4l2 2M18 18l2 2M4 20l2-2M18 6l2-2",
    notification: "M5 17h14l-2-3V9a5 5 0 0 0-10 0v5zM10 21h4",
    lock: "M5 10h14v11H5zM8 10V6a4 4 0 0 1 8 0v4M12 14v3",
    power: "M12 2v10M6 5a9 9 0 1 0 12 0",
    restart: "M20 12a8 8 0 1 1-2.34-5.66M20 4v5h-5",
    sleep: "M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z",
    forward: "M5 12h14M13 6l6 6-6 6",
    screenshot: "M7 3H3v4M17 3h4v4M3 17v4h4M21 17v4h-4M6 7h12v10H6z",
    controls: "M3 6h7M14 6h7M3 18h11M18 18h3M10 3v6M14 15v6",
    folder: "M3 7V5h7l2 2h9v13H3z"
});

export const applications = Object.freeze({
    nova: { label: "NovaShell", glyph: "nova", palette: "blue" },
    files: { label: "Files", glyph: "files", palette: "blue" },
    browser: { label: "Browser", glyph: "browser", palette: "blue" },
    terminal: { label: "Terminal", glyph: "terminal", palette: "slate" },
    settings: { label: "Settings", glyph: "settings", palette: "slate" },
    calendar: { label: "Calendar", glyph: "calendar", palette: "pink" },
    calculator: { label: "Calculator", glyph: "calculator", palette: "orange" },
    music: { label: "Music", glyph: "music", palette: "pink" },
    photos: { label: "Photos", glyph: "photos", palette: "purple" },
    notes: { label: "Notes", glyph: "notes", palette: "orange" },
    weather: { label: "Weather", glyph: "weather", palette: "blue" },
    tasks: { label: "Tasks", glyph: "tasks", palette: "green" },
    monitor: { label: "Monitor", glyph: "monitor", palette: "green" },
    store: { label: "Software", glyph: "store", palette: "purple" },
    trash: { label: "Trash", glyph: "trash", palette: "slate" },
    application: { label: "Application", glyph: "application", palette: "slate" }
});
export const symbolNames = Object.freeze(Object.keys(symbols));
export const applicationNames = Object.freeze(Object.keys(applications));
const sources = new Map();
export const CACHE_LIMIT = 256;

export function application(name) {
    return Object.prototype.hasOwnProperty.call(applications, name)
        ? applications[name] : applications.application;
}
function symbol(name) {
    return Object.prototype.hasOwnProperty.call(symbols, name) ? symbols[name] : symbols.application;
}
function paint(value) {
    // Qt color.toString() uses #AARRGGBB; translate to SVG #RRGGBBAA.
    const s = String(value);
    if (/^#[0-9a-f]{8}$/i.test(s))
        return "#" + s.slice(3) + s.slice(1, 3);
    if (!/^#[0-9a-f]{6}$/i.test(s))
        throw new TypeError("Expected a six- or eight-digit color");
    return s;
}
function cached(key, create) {
    if (sources.has(key)) {
        const value = sources.get(key);
        sources.delete(key);
        sources.set(key, value);
        return value;
    }
    const value = "data:image/svg+xml;utf8," + encodeURIComponent(create());
    if (sources.size >= CACHE_LIMIT)
        sources.delete(sources.keys().next().value);
    sources.set(key, value);
    return value;
}
export function cacheSize() { return sources.size; }
export function symbolSource(name, color, stroke = "1.7") {
    const ink = paint(color);
    const width = Number(stroke);
    if (!Number.isFinite(width) || width < 0.5 || width > 4)
        throw new RangeError("Invalid icon stroke");
    const path = symbol(name);
    return cached(JSON.stringify([path, ink, width]), () =>
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        + '<path fill="none" stroke="' + ink + '" stroke-width="' + width
        + '" stroke-linecap="round" stroke-linejoin="round" d="' + path + '"/></svg>');
}
export function tilePath() {
    const points = [];
    // Fixed 13 samples per corner: generated once, not per frame.
    for (let corner = 0; corner < 4; corner++) {
        for (let step = 0; step <= 12; step++) {
            const y = -28 + 13 * step / 12;
            const x = Corners.halfExtentAt(-y, 28, 28, 13, 4);
            const rotated = [[x, y], [-y, x], [-x, -y], [y, -x]][corner];
            points.push((32 + rotated[0]).toFixed(3) + " " + (32 + rotated[1]).toFixed(3));
        }
    }
    return "M" + points.join("L") + "Z";
}
const tile = tilePath();

export function applicationSource(name, appearance, style) {
    const entry = application(name);
    const mode = ["default", "dark", "clear", "tinted"].includes(appearance) ? appearance : "default";
    // Only inputs that affect this appearance participate in its cache key.
    // Changing the accent must not rerasterize normal application artwork.
    const palette = mode === "default" ? style.palette.map(paint) : null;
    const foreground = mode === "default" ? paint(style.white)
        : mode === "dark" ? paint(style.palette[0])
        : mode === "tinted" ? paint(style.tint) : paint(style.ink);
    const background = mode === "default" ? "url(#base)"
        : mode === "dark" ? paint(style.darkTile)
        : mode === "tinted" ? paint(style.tint) : paint(style.tile);
    const edge = paint(mode === "dark" ? style.darkEdge : style.lightEdge);
    const highlight = paint(style.highlight);
    const clearOpacity = Math.max(0, Math.min(1, Number(style.clearOpacity)));
    if (!Number.isFinite(clearOpacity)) throw new TypeError("Invalid clear opacity");
    const opacity = mode === "tinted" ? Math.max(0.18, clearOpacity) : mode === "clear" ? clearOpacity : 1;
    return cached(JSON.stringify([entry.glyph, foreground, background, opacity, palette, edge, highlight]), () =>
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64">'
        + '<defs><path id="tile" d="' + tile + '"/>'
        + (palette ? '<linearGradient id="base" x2="0" y2="1"><stop stop-color="' + palette[0]
        + '"/><stop offset="1" stop-color="' + palette[1] + '"/></linearGradient>' : "")
        + '<linearGradient id="shine" x2="0" y2="1"><stop stop-color="' + highlight
        + '" stop-opacity=".42"/><stop offset=".55" stop-color="' + highlight
        + '" stop-opacity="0"/></linearGradient></defs>'
        + '<use xlink:href="#tile" fill="' + background + '" fill-opacity="' + opacity + '"/>'
        + '<use xlink:href="#tile" fill="url(#shine)" stroke="' + edge + '" stroke-opacity=".55" stroke-width=".7"/>'
        + '<path transform="translate(16 16) scale(1.333333)" d="' + symbol(entry.glyph)
        + '" fill="none" stroke="' + foreground
        + '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>');
}
