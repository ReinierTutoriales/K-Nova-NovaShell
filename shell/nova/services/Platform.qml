// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell
import "DesktopPolicy.mjs" as Policy

// Única puerta del shell hacia el sistema. La UI nunca ejecuta comandos
// (nmcli, wpctl, systemctl, qdbus…): pide operaciones del contrato IPC v1
// (docs/CONTRATO-IPC-v1.md) y el daemon nova-platform decide.
Singleton {
    id: platform

    readonly property bool connected: client.connected
    // Datos de platform.version; vacío hasta la primera conexión.
    property string daemonVersion: ""
    property var operations: []
    property string lastError: ""
    property var applications: []
    property var windows: []
    property var desktops: []
    property string activeWindow: ""
    property string currentDesktop: ""
    property bool windowBridgeAvailable: false
    property bool applicationsLoading: false
    // -1 until the daemon supplies a known total; never invent a percentage.
    property real applicationsProgress: -1
    property var brightness: ({available: false, displays: []})
    property var metrics: ({available: false})
    property int _catalogGeneration: 0
    property string _pendingWindow: ""
    property string _pendingSource: ""
    property double _pendingAt: 0
    property PreferencesBridge preferences: PreferencesBridge {
        onPatchRequested: changes => platform.call("settings.patch", changes, result => preferences.apply(result.values))
    }
    property NativeDesktop desktop: NativeDesktop {
        scanning: ShellState.panel === "controls"
        clipboardEnabled: platform.preferences.values.clipboardEnabled || false
        brightnessState: platform.brightness
        onBrightnessRequested: (id, percent) => platform.call("brightness.set", {id: id, percent: percent})
        onSessionRequested: action => platform.call("session.action", {action: action})
        onScreenshotRequested: platform.call("screenshot.capture", {})
        onError: message => platform.lastError = message
    }
    property Loader notificationLoader: Loader {
        active: platform.preferences.values.notificationServer || false
        sourceComponent: Component {
            NotificationBackend { doNotDisturb: platform.preferences.values.doNotDisturb || false }
        }
    }
    readonly property var notifications: notificationLoader.item
    readonly property var dockItems: Policy.dock(applications, preferences.values.pins || [], windows)
    // Pantallas con widgets de escritorio visibles (lo mantiene DesktopWidgets).
    property int desktopWidgetsActive: 0
    // Métricas para los widgets del escritorio: cada 10 s y solo si existen.
    property Timer widgetRefresh: Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: platform.connected && platform.desktopWidgetsActive > 0 && ShellState.panel !== "widgets"
        onTriggered: platform.call("system.metrics", {}, result => platform.metrics = result)
    }
    property Timer panelRefresh: Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: platform.connected && (ShellState.panel === "controls" || ShellState.panel === "widgets")
        onTriggered: {
            if (ShellState.panel === "controls") platform.call("brightness.get", {}, result => platform.brightness = result);
            if (ShellState.panel === "widgets") platform.call("system.metrics", {}, result => platform.metrics = result);
        }
    }
    function call(operation, payload, success) {
        return request(operation, payload, response => {
            if (response.ok) { lastError = ""; if (success) success(response.result); }
            else lastError = response.error?.message || qsTr("Operación no disponible");
        });
    }
    function launch(id) { call("application.launch", {id: id}); }
    function iconUrl(name) {
        if (!name) return "";
        if (name.startsWith("/") || name.startsWith("file:") || name.startsWith("image:"))
            return name.startsWith("/") ? "file://" + encodeURI(name) : name;
        return Quickshell.iconPath(name, true);
    }
    function windowAction(action, id) { call("window.action", Array.isArray(id) ? {action: action, ids: id} : {action: action, id: id || ""}); }
    function activateApplication(entry) {
        if (!entry.windows.length) { launch(entry.id); return; }
        const next = Policy.nextWindow(entry.windows, activeWindow, _pendingWindow, _pendingSource, Date.now() - _pendingAt);
        _pendingWindow = next.id;
        _pendingSource = activeWindow;
        _pendingAt = Date.now();
        windowAction("activate", next.id);
    }
    function applyWindows(snapshot) {
        windows = snapshot.windows || [];
        desktops = snapshot.desktops || [];
        activeWindow = snapshot.activeWindow || "";
        currentDesktop = snapshot.currentDesktop || "";
        windowBridgeAvailable = snapshot.available || false;
    }
    function reloadApplications() {
        // client.connected, no platform.connected: al conectar, este método se
        // llama desde onConnectedChanged del cliente, antes de que el binding
        // de platform.connected se reevalúe; leerlo daba false y el catálogo
        // (y con él el dock) nunca se cargaba.
        if (!client.connected || applicationsLoading) return;
        const generation = ++_catalogGeneration;
        applicationsLoading = true;
        applicationsProgress = -1;
        let collected = [];
        function page(offset) {
            request("applications.list", {offset: offset, limit: 24}, response => {
                if (generation !== _catalogGeneration) return;
                if (!response.ok) { applicationsLoading = false; lastError = response.error.message; return; }
                collected = collected.concat(response.result.applications);
                const total = response.result.total;
                applicationsProgress = Number.isFinite(total) && total > 0
                    ? Math.min(1, collected.length / total) : -1;
                if (response.result.next > offset && response.result.next < response.result.total && collected.length < 10000)
                    page(response.result.next);
                else { applications = collected; applicationsLoading = false; }
            });
        }
        page(0);
    }

    function request(operation, payload, callback) {
        return client.request(operation, payload, callback)
    }

    function has(operation) {
        return operations.indexOf(operation) >= 0
    }

    signal eventReceived(string name, var payload)

    property JsonlClient client: JsonlClient {
        logName: "Platform"
        socketPath: Quickshell.env("XDG_RUNTIME_DIR") + "/novashell/platform.sock"
        readOperations: ["platform.ping", "platform.version", "platform.capabilities",
            "compositor.capabilities", "applications.list", "settings.get", "windows.list",
            "brightness.get", "system.metrics"]

        onEventReceived: (name, payload) => {
            if (name === "windows.changed") platform.applyWindows(payload);
            if (name === "brightness.changed") platform.brightness = payload;
            if (name === "system.action" && !payload.ok) platform.lastError = payload.message;
            if (name === "desktop.shortcut") ShellState.toggle(payload.panel, ShellState.screen || Quickshell.screens[0]);
            platform.eventReceived(name, payload);
        }
        onConnectedChanged: {
            if (!connected) {
                platform.daemonVersion = ""
                platform.operations = []
                ++platform._catalogGeneration;
                platform.applicationsLoading = false;
                platform.applicationsProgress = -1;
                platform.applyWindows({});
                return
            }
            request("platform.version", {}, response => {
                if (response.ok)
                    platform.daemonVersion = response.result.version
            })
            request("platform.capabilities", {}, response => {
                if (response.ok)
                    platform.operations = response.result.operations
            })
            platform.call("settings.get", {}, result => platform.preferences.apply(result.values));
            platform.call("windows.list", {}, result => platform.applyWindows(result));
            platform.reloadApplications();
        }
    }
}
