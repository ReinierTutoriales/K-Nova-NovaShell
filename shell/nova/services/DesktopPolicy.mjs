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
export function search(applications, query) {
    const words = String(query || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim().split(/\s+/).filter(Boolean);
    return applications.filter(app => words.every(word =>
        String(app.name + " " + app.id + " " + (app.keywords || "")).normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "").toLowerCase().includes(word)));
}
export function dock(applications, pins, windows) {
    const byId = new Map(applications.map(app => [identity(app.id), app]));
    const groups = new Map();
    for (const window of windows) {
        let key = identity(window.appId);
        if (!byId.has(key)) {
            const matches = applications.filter(app => identity(app.id).split(".").pop() === key);
            if (matches.length === 1) key = identity(matches[0].id);
        }
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(window);
    }
    const ordered = [...new Set([...pins.map(identity), ...groups.keys()])];
    return ordered.map(key => {
        const app = byId.get(key), group = groups.get(key) || [];
        if (!app && group.length === 0) return null;
        return {id: app?.id || key + ".desktop", name: app?.name || group[0].title || key,
            icon: app?.icon || "application-x-executable", windows: group,
            pinned: pins.some(pin => identity(pin) === key)};
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
