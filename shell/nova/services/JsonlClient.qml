// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io

// Cliente JSONL genérico para los sockets de NovaShell (contrato IPC v1).
//
// Garantías:
// - Las lecturas idempotentes (readOperations) esperan en cola mientras el
//   daemon no está, con tope; las escrituras fallan al instante: un "apagar"
//   nunca se ejecuta minutos después de que el usuario lo pulsó.
// - Toda petición enviada caduca (requestTimeoutMs); una desconexión falla
//   todo lo pendiente, así ningún consumidor queda esperando para siempre.
// - El Socket de Quickshell solo intenta conectar una vez por instancia, así
//   que la reconexión crea un Socket nuevo con espera exponencial.
QtObject {
    id: client

    readonly property int protocolVersion: 1
    property string socketPath: ""
    property bool enabled: true
    property string logName: "JsonlClient"
    property var readOperations: []
    property int maxQueueSize: 50
    property int requestTimeoutMs: 10000

    readonly property bool connected: _socket !== null && _socket.connected

    signal eventReceived(string name, var payload)

    // ---- API pública ---------------------------------------------------

    function request(operation, payload, callback) {
        const id = String(_nextId++)
        const line = JSON.stringify({
            version: protocolVersion, requestId: id,
            operation: operation, payload: payload || {}
        }) + "\n"
        const entry = { callback: callback, line: line, sentAt: 0 }

        if (connected) {
            _send(id, entry)
        } else if (readOperations.indexOf(operation) >= 0 && _queue.length < maxQueueSize) {
            _queue.push(id)
            _pending.set(id, entry)
        } else {
            _reply(entry, _error("unavailable", "servicio no disponible", true))
        }
        return id
    }

    // ---- Implementación ------------------------------------------------

    property var _socket: null
    property var _pending: new Map()   // requestId -> entry
    property var _queue: []            // requestIds en espera de conexión
    property int _nextId: 1
    property int _backoffMs: 500

    function _error(code, message, retryable) {
        return { version: protocolVersion, ok: false,
                 error: { code: code, message: message, retryable: retryable } }
    }

    function _reply(entry, response) {
        if (!entry || typeof entry.callback !== "function")
            return
        try {
            entry.callback(response)
        } catch (e) {
            console.warn("[" + logName + "] error en callback: " + e)
        }
    }

    function _send(id, entry) {
        entry.sentAt = Date.now()
        _pending.set(id, entry)
        _socket.write(entry.line)
        _socket.flush()
    }

    function _flushQueue() {
        const ids = _queue
        _queue = []
        for (const id of ids) {
            const entry = _pending.get(id)
            if (entry)
                _send(id, entry)
        }
    }

    function _failAll(code, message) {
        const entries = Array.from(_pending.values())
        _pending = new Map()
        _queue = []
        for (const entry of entries)
            _reply(entry, _error(code, message, true))
    }

    function _readLine(line) {
        let message
        try {
            message = JSON.parse(line)
        } catch (e) {
            console.warn("[" + logName + "] línea no válida del daemon")
            return
        }
        if (typeof message.event === "string") {
            eventReceived(message.event, message.payload || {})
            return
        }
        const entry = _pending.get(message.requestId)
        if (!entry)
            return // respuesta tardía de algo ya caducado
        _pending.delete(message.requestId)
        _reply(entry, message)
    }

    function _expire() {
        const now = Date.now()
        for (const [id, entry] of Array.from(_pending.entries())) {
            if (entry.sentAt > 0 && now - entry.sentAt > requestTimeoutMs) {
                _pending.delete(id)
                _reply(entry, _error("timeout", "el daemon no respondió a tiempo", true))
            }
        }
    }

    function _connect() {
        if (!enabled || socketPath === "")
            return
        if (_socket !== null) {
            _socket.stale = true
            _socket.destroy()
        }
        _socket = socketFactory.createObject(client)
        _socket.connected = true
    }

    property Component socketFactory: Component {
        Socket {
            id: socket
            // Un Socket reemplazado sigue vivo hasta su destroy() diferido:
            // stale impide que un evento tardío afecte al Socket nuevo.
            property bool stale: false
            path: client.socketPath
            connected: false
            parser: SplitParser {
                splitMarker: "\n"
                onRead: data => {
                    if (!socket.stale)
                        client._readLine(data)
                }
            }
            onConnectedChanged: {
                if (socket.stale)
                    return
                if (connected) {
                    client._backoffMs = 500
                    console.info("[" + client.logName + "] conectado")
                    client._flushQueue()
                } else {
                    // _reconnectTimer arranca solo: su running sigue a !connected.
                    client._failAll("disconnected", "el daemon se desconectó")
                }
            }
        }
    }

    property Timer _reconnectTimer: Timer {
        interval: client._backoffMs
        repeat: true
        running: client.enabled && !client.connected
        triggeredOnStart: true
        onTriggered: {
            client._connect()
            client._backoffMs = Math.min(client._backoffMs * 2, 8000)
        }
    }

    property Timer _expiryTimer: Timer {
        interval: 1000
        repeat: true
        // Un Map no notifica cambios a los bindings: barrido fijo de 1 s.
        running: client.enabled
        onTriggered: client._expire()
    }
}
