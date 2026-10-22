// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth

QtObject {
    id: desktop
    property bool scanning: false
    property bool clipboardEnabled: false
    property var clipboardHistory: []
    signal error(string message)
    signal brightnessRequested(string id, int percent)
    signal sessionRequested(string action)
    signal screenshotRequested()
    property var brightnessState: ({available: false, displays: []})
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: !!sink && sink.ready && !!sink.audio
    readonly property real volume: audioAvailable ? sink.audio.volume : 0
    readonly property bool muted: audioAvailable && sink.audio.muted
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream)
    readonly property var trayItems: SystemTray.items.values
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery && battery.isPresent
    readonly property real batteryPercent: batteryPresent ? battery.percentage : 0
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(item => item.isPlaying) || players[0] || null
    readonly property var networkDevices: Networking.devices.values
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiAvailable: networkDevices.some(device => device instanceof WifiDevice)
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: !!bluetoothAdapter
    readonly property bool bluetoothEnabled: !!bluetoothAdapter && bluetoothAdapter.enabled
    readonly property var bluetoothDevices: Bluetooth.devices.values
    property PwObjectTracker audioTracker: PwObjectTracker { objects: desktop.outputs }
    function setVolume(value) { if (audioAvailable) sink.audio.volume = Math.max(0, Math.min(1, value)); }
    function toggleMute() { if (audioAvailable) sink.audio.muted = !sink.audio.muted; }
    function setBrightness(id, percent) { brightnessRequested(id, percent); }
    function session(action) { sessionRequested(action); }
    function screenshot() { screenshotRequested(); }
    function setOutput(node) { if (outputs.indexOf(node) >= 0) Pipewire.preferredDefaultAudioSink = node; }
    function setWifi(value) { Networking.wifiEnabled = value; }
    function setBluetooth(value) { if (bluetoothAdapter) bluetoothAdapter.enabled = value; }
    function setScanning() {
        for (const device of networkDevices)
            if (device instanceof WifiDevice) device.scannerEnabled = scanning;
    }
    onScanningChanged: setScanning()
    onNetworkDevicesChanged: setScanning()
    function connectNetwork(network, password) {
        if (password) network.connectWithPsk(password);
        else network.connect();
    }
    function toggleBluetoothDevice(device) {
        if (device.connected) device.disconnect();
        else if (device.paired) device.connect();
        else device.pair();
    }
    function activateTray(item, window) {
        if (item.onlyMenu) item.display(window, 0, window.height);
        else item.activate();
    }
    function trayMenu(item, window) { if (item.hasMenu) item.display(window, 0, window.height); }
    function copy(text) { Quickshell.clipboardText = text; }
    function clearClipboard() { clipboardHistory = []; }
    onClipboardEnabledChanged: if (!clipboardEnabled) clearClipboard()
    property Connections clipboardConnection: Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            const text = Quickshell.clipboardText;
            if (desktop.clipboardEnabled && text && text.length <= 4096)
                desktop.clipboardHistory = [text, ...desktop.clipboardHistory.filter(entry => entry !== text)].slice(0, 30);
        }
    }
}
