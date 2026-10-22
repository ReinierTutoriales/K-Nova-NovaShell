// SPDX-License-Identifier: GPL-3.0-only
// Event driven snapshots and one outstanding command request, no idle polling.
const service = "org.nova.Shell";
const path = "/Windows";
const iface = "org.nova.Shell.Windows";
let previous = "";
function id(window) { return String(window.internalId || "").replace(/[{}]/g, ""); }
function hook(object, signal, callback) {
    try { if (object[signal] && object[signal].connect) object[signal].connect(callback); } catch (_) {}
}
function eligible(window) {
    return window && !window.deleted && window.normalWindow && !window.skipTaskbar
        && !window.skipSwitcher && !window.inputMethod;
}
function snapshot() {
    const windows = workspace.windowList().filter(eligible).slice(0, 128).map(window => {
        const geometry = window.frameGeometry;
        return {id: id(window), appId: String(window.desktopFileName || window.resourceClass || "").slice(0, 256),
            title: String(window.caption || "").slice(0, 160), minimized: !!window.minimized,
            active: workspace.activeWindow === window, fullscreen: !!window.fullScreen,
            maximized: Number(window.maximizeMode || 0) === 3, screen: window.output ? String(window.output.name) : "",
            desktops: (window.desktops || []).map(desktop => String(desktop.id)),
            geometry: {x: geometry.x, y: geometry.y, width: geometry.width, height: geometry.height}};
    });
    const value = JSON.stringify({windows: windows,
        activeWindow: workspace.activeWindow ? id(workspace.activeWindow) : "",
        currentDesktop: workspace.currentDesktop ? String(workspace.currentDesktop.id) : "",
        desktops: workspace.desktops.map(desktop => ({id: String(desktop.id), name: String(desktop.name).slice(0, 80)}))});
    if (value !== previous && value.length < 60000) {
        previous = value;
        callDBus(service, path, iface, "Publish", value);
    }
}
const debounce = new QTimer();
debounce.interval = 35;
debounce.singleShot = true;
debounce.timeout.connect(snapshot);
function schedule() { if (!debounce.active) debounce.start(); }
function watch(window) {
    for (const signal of ["captionChanged", "minimizedChanged", "maximizedChanged", "maximizeModeChanged", "fullScreenChanged",
                           "frameGeometryChanged", "desktopsChanged", "outputChanged", "closed"])
        hook(window, signal, schedule);
}
workspace.windowList().forEach(watch);
hook(workspace, "windowAdded", window => { watch(window); schedule(); });
for (const signal of ["windowRemoved", "windowActivated", "currentDesktopChanged", "desktopsChanged"])
    hook(workspace, signal, schedule);
function execute(raw) {
    if (!raw) return;
    try {
        const command = JSON.parse(raw);
        if (command.action === "desktop") {
            const desktop = workspace.desktops.find(item => String(item.id) === command.id);
            if (desktop) workspace.currentDesktop = desktop;
            return;
        }
        const ids = command.ids || [command.id];
        for (const window of workspace.windowList().filter(item => ids.indexOf(id(item)) >= 0 && eligible(item))) {
            if (command.action === "activate") { window.minimized = false; workspace.activeWindow = window; }
            else if (command.action === "minimize") window.minimized = true;
            else if (command.action === "maximize") window.setMaximize(Number(window.maximizeMode || 0) !== 3, Number(window.maximizeMode || 0) !== 3);
            else if (command.action === "close") window.closeWindow();
        }
        schedule();
    } catch (_) {}
}
const retry = new QTimer();
retry.interval = 1000;
retry.singleShot = true;
let waiting = false;
let age = 0;
function listen() {
    if (waiting) return;
    waiting = true;
    age = 0;
    callDBus(service, path, iface, "TakeCommand", raw => {
        waiting = false;
        execute(raw);
        retry.interval = raw ? 1 : 100;
        retry.start();
    });
}
retry.timeout.connect(listen);
const heartbeat = new QTimer();
heartbeat.interval = 5000;
heartbeat.timeout.connect(() => {
    age += 5000;
    if (age >= 20000) { waiting = false; previous = ""; snapshot(); listen(); }
});
heartbeat.start();
snapshot();
listen();
if (typeof registerShortcut === "function") {
    for (const shortcut of [
        ["nova-launcher", "Nova: Aplicaciones", "Meta+Space", "launcher"],
        ["nova-control", "Nova: Centro de control", "Meta+Shift+C", "controls"],
        ["nova-overview", "Nova: Ventanas", "Meta+Shift+W", "overview"],
        ["nova-clipboard", "Nova: Portapapeles", "Meta+Shift+V", "clipboard"]
    ]) registerShortcut(shortcut[0], shortcut[1], shortcut[2], () => callDBus(service, path, iface, "Shortcut", shortcut[3]));
}
