// SPDX-License-Identifier: GPL-3.0-only
export function identity(value) { return String(value || "").replace(/\.desktop$/i, "").toLowerCase(); }
export function sourceKey(notification) {
    const desktop = identity(String(notification.desktopEntry || "").trim());
    return desktop ? "desktop:" + desktop : "name:" + String(notification.appName || "Aplicación").trim();
}
export function influenceAt(distance, radius) {
    const t = Math.min(1, Math.abs(distance) / Math.max(1, radius));
    return 1 - t * t * t * (10 + t * (-15 + 6 * t));
}
// Búsqueda del lanzador. Sin acentos ni mayúsculas; varias palabras deben
// coincidir todas. Ordena por relevancia para que Intro abra lo esperado:
// inicio del nombre > inicio de palabra > iniciales ("lc" → LibreOffice
// Calc) > dentro del nombre > nombre genérico, palabras clave o ID. A igual
// relevancia se conserva el orden alfabético del catálogo.
export function fold(value) {
    return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}
function words(value) { return fold(value).replace(/[^a-z0-9]+/g, " ").trim(); }
// Índice normalizado una vez por catálogo (no en cada pulsación).
export function searchIndex(applications) {
    return applications.map((app, order) => {
        const name = words(app.name);
        return {app, order, name, initials: name.split(" ").map(part => part[0] || "").join(""),
            extra: words([app.genericName, app.keywords, identity(app.id)].join(" "))};
    });
}
function wordScore(entry, word) {
    if (entry.name.startsWith(word)) return 100;
    if ((" " + entry.name).includes(" " + word)) return 70;
    if (word.length > 1 && entry.initials.startsWith(word)) return 60;
    if (entry.name.includes(word)) return 40;
    if ((" " + entry.extra).includes(" " + word)) return 25;
    return entry.extra.includes(word) ? 10 : 0;
}
export function search(applications, query, index) {
    const terms = words(query).split(" ").filter(Boolean);
    if (!terms.length) return applications;
    const scored = [];
    for (const entry of index || searchIndex(applications)) {
        let score = 0;
        for (const term of terms) {
            const value = wordScore(entry, term);
            if (!value) { score = 0; break; }
            score += value;
        }
        if (score) scored.push(entry);
        entry.score = score;
    }
    return scored.sort((a, b) => b.score - a.score || a.order - b.order).map(entry => entry.app);
}
export function dock(applications, pins, windows) {
    const byId = new Map(applications.map(app => [identity(app.id), app]));
    // Resolve short IDs once, preserving ambiguity rather than scanning the
    // full application catalog again for each live window.
    const shortIds = new Map();
    for (const app of applications) {
        const key = identity(app.id), short = key.split(".").pop();
        shortIds.set(short, shortIds.has(short) ? null : key);
    }
    const pinned = new Set(pins.map(identity));
    const groups = new Map();
    for (const window of windows) {
        let key = identity(window.appId);
        if (!byId.has(key) && shortIds.get(key)) key = shortIds.get(key);
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(window);
    }
    const ordered = [...new Set([...pinned, ...groups.keys()])];
    return ordered.map(key => {
        const app = byId.get(key), group = groups.get(key) || [];
        if (!app && group.length === 0) return null;
        return {id: app?.id || key + ".desktop", name: app?.name || group[0].title || key,
            icon: app?.icon || "application-x-executable", windows: group,
            pinned: pinned.has(key)};
    }).filter(Boolean);
}
export function nextWindow(windows, activeId, pendingId, pendingSource, pendingAge) {
    if (!windows.length) return null;
    let index = windows.findIndex(window => window.id === activeId);
    if (pendingId && pendingId !== activeId && pendingSource === activeId && pendingAge >= 0 && pendingAge < 800) {
        const pending = windows.findIndex(window => window.id === pendingId);
        if (pending >= 0) index = pending;
    }
    return windows[(index + 1) % windows.length];
}
