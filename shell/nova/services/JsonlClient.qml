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
// - La reconexión crea un Socket nuevo con espera exponencial y aísla
//   los eventos tardíos de conexiones anteriores.
QtObject {
    id: client

    readonly property int protocolVersion: 1
    property string socketPath: ""
    property bool enabled: true
    property string logName: "JsonlClient"
    property var readOperations: []
    property int maxQueueSize: 50
    property int maxPendingSize: 128
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
        const entry = { callback: callback, line: line, createdAt: Date.now() }

        if (!enabled || _pending.size >= maxPendingSize) {
            _reply(entry, _error("unavailable", "cliente deshabilitado o demasiadas peticiones pendientes", true))
            return id
        }

        if (connected) {
            _send(id, entry)
        } else if (readOperations.indexOf(operation) >= 0 && _queue.length < maxQueueSize) {
            _queue.push(id)
            _pending.set(id, entry)
            _syncPending()
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
    // Espejo de _pending.size: un Map no notifica a los bindings, y este
    // contador permite que el barrido de caducidad solo corra cuando hay
    // peticiones en vuelo (cero despertares en reposo).
    property int _pendingCount: 0

    function _syncPending() {
        _pendingCount = _pending.size
    }

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
        _pending.set(id, entry)
        _syncPending()
        _socket.write(entry.line)
        _socket.flush()
    }

    function _flushQueue() {
        const ids = _queue
        _queue = []
        for (const id of ids) {
            const entry = _pending.get(id)
            if (entry && connected && enabled)
                _send(id, entry)
        }
    }

    function _failAll(code, message) {
        const entries = Array.from(_pending.values())
        _pending = new Map()
        _queue = []
        _syncPending()
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
        if (!message || typeof message !== "object" || Array.isArray(message) || message.version !== protocolVersion)
            return
        if (typeof message.event === "string") {
            eventReceived(message.event, message.payload || {})
            return
        }
        const entry = _pending.get(message.requestId)
        if (!entry)
            return // respuesta tardía de algo ya caducado
        _pending.delete(message.requestId)
        _syncPending()
        _reply(entry, message)
    }

    function _expire() {
        const now = Date.now()
        for (const [id, entry] of Array.from(_pending.entries())) {
            if (_pending.has(id) && now - entry.createdAt >= requestTimeoutMs) {
                _pending.delete(id)
                _reply(entry, _error("timeout", "el daemon no respondió a tiempo", true))
            }
        }
        _syncPending()
        _queue = _queue.filter(id => _pending.has(id))
    }

    function _resetConnection() {
        if (_socket !== null) {
            _socket.stale = true
            _socket.connected = false
            _socket.destroy()
            _socket = null
        }
        _failAll("disconnected", "la conexión se reinició")
        _backoffMs = 500
    }
    onEnabledChanged: if (!enabled) _resetConnection()
    onSocketPathChanged: if (_socket !== null) _resetConnection()

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
        running: client.enabled && client.socketPath !== "" && !client.connected
        triggeredOnStart: true
        onTriggered: {
            client._connect()
            client._backoffMs = Math.min(client._backoffMs * 2, 8000)
        }
    }

    property Timer _expiryTimer: Timer {
        interval: 1000
        repeat: true
        // También caducan las lecturas en cola; sin peticiones no despierta.
        running: client.enabled && client._pendingCount > 0
        onTriggered: client._expire()
    }
}
