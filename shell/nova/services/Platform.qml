// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import Quickshell

// Única puerta del shell hacia el sistema. La UI nunca ejecuta comandos
// (nmcli, wpctl, systemctl, qdbus…): pide operaciones del contrato IPC v1
// (docs/CONTRATO-IPC-v1.md) y el daemon nova-platform decide.
Singleton {
    id: platform

    readonly property bool connected: client.connected
    // Datos de platform.version; vacío hasta la primera conexión.
    property string daemonVersion: ""
    property var operations: []

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
            "compositor.capabilities"]

        onEventReceived: (name, payload) => platform.eventReceived(name, payload)
        onConnectedChanged: {
            if (!connected) {
                platform.daemonVersion = ""
                platform.operations = []
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
        }
    }
}
