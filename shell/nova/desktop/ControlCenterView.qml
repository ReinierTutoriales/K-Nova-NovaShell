// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls
import qs.nova.icons

ScrollView {
    id: center
    required property var backend
    property bool doNotDisturb: false
    signal doNotDisturbRequested(bool enabled)
    signal settingsRequested()
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        width: center.availableWidth
        spacing: Theme.space.md
        RowLayout {
            Layout.fillWidth: true
            NovaButton {
                text: qsTr("Wi-Fi")
                symbol: "wifi"
                checkable: true
                checked: center.backend.wifiEnabled
                enabled: center.backend.wifiAvailable
                Layout.fillWidth: true
                onClicked: center.backend.setWifi(!center.backend.wifiEnabled)
            }
            NovaButton {
                text: qsTr("Bluetooth")
                symbol: "bluetooth"
                checkable: true
                checked: center.backend.bluetoothEnabled
                enabled: center.backend.bluetoothAvailable
                Layout.fillWidth: true
                onClicked: center.backend.setBluetooth(!center.backend.bluetoothEnabled)
            }
        }
        Text { text: qsTr("Sonido"); color: Theme.color.text; font.pixelSize: Theme.font.title }
        RowLayout {
            IconButton { label: qsTr("Silenciar"); symbol: "volume"; enabled: center.backend.audioAvailable; onClicked: center.backend.toggleMute() }
            Slider {
                Layout.fillWidth: true
                from: 0; to: 1
                value: center.backend.volume
                enabled: center.backend.audioAvailable
                Accessible.name: qsTr("Volumen")
                onMoved: center.backend.setVolume(value)
            }
            Text { text: Math.round(center.backend.volume * 100) + "%"; color: Theme.color.text; font.pixelSize: Theme.font.body }
        }
        Repeater {
            model: center.backend.outputs
            NovaButton {
                required property var modelData
                text: modelData.description || modelData.nickname || modelData.name
                Layout.fillWidth: true
                checkable: true
                checked: modelData === center.backend.sink
                onClicked: center.backend.setOutput(modelData)
            }
        }
        NovaButton {
            text: qsTr("No molestar")
            symbol: "notification"
            checkable: true
            checked: center.doNotDisturb
            Layout.fillWidth: true
            onClicked: center.doNotDisturbRequested(!center.doNotDisturb)
        }
        Text {
            visible: center.backend.batteryPresent
            text: qsTr("Batería: %1 %").arg(Math.round(center.backend.batteryPercent * 100))
            color: Theme.color.text
            font.pixelSize: Theme.font.body
        }
        Text { text: qsTr("Redes disponibles"); color: Theme.color.text; font.pixelSize: Theme.font.title }
        Repeater {
            model: center.backend.networkDevices
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Repeater {
                    model: modelData.networks
                    NovaButton {
                        required property var modelData
                        text: modelData.name + (modelData.connected ? " ✓" : "")
                        Layout.fillWidth: true
                        enabled: !modelData.stateChanging
                        onClicked: {
                            if (modelData.connected) modelData.disconnect();
                            else { networkPassword.network = modelData; networkPassword.open(); }
                        }
                    }
                }
            }
        }
        Text { text: qsTr("Dispositivos Bluetooth"); color: Theme.color.text; font.pixelSize: Theme.font.title }
        Repeater {
            model: center.backend.bluetoothDevices
            NovaButton {
                required property var modelData
                text: modelData.name + (modelData.connected ? " ✓" : "")
                Layout.fillWidth: true
                enabled: center.backend.bluetoothEnabled && !modelData.pairing
                onClicked: center.backend.toggleBluetoothDevice(modelData)
            }
        }
        NovaButton {
            text: qsTr("Buscar dispositivos")
            enabled: center.backend.bluetoothEnabled
            Layout.fillWidth: true
            onClicked: center.backend.bluetoothAdapter.discovering = !center.backend.bluetoothAdapter.discovering
        }
        ColumnLayout {
            visible: !!center.backend.player
            Text {
                text: center.backend.player ? center.backend.player.trackTitle || center.backend.player.identity : ""
                color: Theme.color.text
                font.pixelSize: Theme.font.title
                textFormat: Text.PlainText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            RowLayout {
                NovaButton { text: qsTr("Anterior"); enabled: !!center.backend.player && center.backend.player.canGoPrevious; onClicked: center.backend.player.previous() }
                NovaButton { text: qsTr("Reproducir / pausa"); enabled: !!center.backend.player && center.backend.player.canTogglePlaying; onClicked: center.backend.player.togglePlaying() }
                NovaButton { text: qsTr("Siguiente"); enabled: !!center.backend.player && center.backend.player.canGoNext; onClicked: center.backend.player.next() }
            }
        }
        NovaButton { text: qsTr("Preferencias"); symbol: "settings"; Layout.fillWidth: true; onClicked: center.settingsRequested() }
    }
    Dialog {
        id: networkPassword
        property var network: null
        title: network ? network.name : qsTr("Conectar")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        onOpened: password.clear()
        onAccepted: center.backend.connectNetwork(network, password.text)
        onClosed: password.clear()
        TextField { id: password; echoMode: TextInput.Password; placeholderText: qsTr("Contraseña; vacía para una red guardada"); Accessible.name: qsTr("Contraseña de Wi-Fi") }
    }
}
