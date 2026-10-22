# SPDX-License-Identifier: GPL-3.0-or-later
"""Test the actual Quickshell socket client against a silent Unix server."""
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix="nova-jsonl-") as temporary:
        directory = Path(temporary)
        # JsonlClient is intentionally internal to services. Import its actual
        # source from a local test directory without exporting a private API.
        (directory / "client").mkdir()
        (directory / "client/JsonlClient.qml").symlink_to(ROOT / "shell/nova/services/JsonlClient.qml")
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(str(directory / "silent.sock"))
        server.listen(1)
        server.settimeout(10)
        received = bytearray()
        failures = []

        def receive():
            try:
                connection, _ = server.accept()
                with connection:
                    connection.settimeout(5)
                    while True:
                        data = connection.recv(4096)
                        if not data:
                            break
                        received.extend(data)
            except OSError as error:
                failures.append(str(error))

        worker = threading.Thread(target=receive, daemon=True)
        worker.start()
        (directory / "shell.qml").write_text('''// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import "./client"
ShellRoot {
    id: root
    property int phase: 0
    property int attempts: 0
    property bool disabledRejected: false
    property bool saturated: false
    property bool resolved: false
    property bool cancelled: false
    property bool expired: false
    property bool oversized: false
    property JsonlClient offline: JsonlClient {
        socketPath: ""
        readOperations: ["platform.ping"]
        requestTimeoutMs: 30
    }
    property JsonlClient live: JsonlClient {
        socketPath: Quickshell.env("XDG_RUNTIME_DIR") + "/silent.sock"
        enabled: false
        maxPendingSize: 2
        readOperations: ["platform.ping"]
    }
    function check(value, message) {
        if (!value) { console.error("NOVA_JSONL_FAILED " + message); Qt.quit(); }
        return value;
    }
    Timer {
        running: true; repeat: true; interval: 20
        onTriggered: {
            if (++root.attempts > 200) { console.error("NOVA_JSONL_FAILED timeout"); Qt.quit(); return; }
            if (root.phase === 0) {
                live.request("platform.ping", {}, response => root.disabledRejected = !response.ok);
                if (!root.check(root.disabledRejected && live._pendingCount === 0, "disabled request")) return;
                offline.request("platform.ping", {text:"界".repeat(25000)}, response => root.oversized = response.error.code === "request-too-large");
                if (!root.check(root.oversized && offline._pendingCount === 0, "UTF-8 size limit")) return;
                offline.request("platform.ping", {}, response => root.expired = response.error.code === "timeout");
                live.enabled = true;
                root.phase = 1;
            } else if (root.phase === 1 && live.connected) {
                const first = live.request("platform.ping", {}, response => root.resolved = response.ok);
                live.request("platform.ping", {}, response => root.cancelled = response.error.code === "disconnected");
                live.request("platform.ping", {}, response => root.saturated = response.error.code === "unavailable");
                if (!root.check(root.saturated && live._pendingCount === 2, "pending bound")) return;
                for (const line of ["null", "[]", "42", JSON.stringify({version:2, requestId:first, ok:true}),
                    JSON.stringify({version:1, requestId:first}), JSON.stringify({version:1, requestId:first, ok:true, result:null})]) live._readLine(line);
                if (!root.check(live._pendingCount === 2, "invalid response")) return;
                live._readLine(JSON.stringify({version:1, requestId:first, ok:true, result:{ready:true}}));
                live.enabled = false;
                root.phase = 2;
            } else if (root.phase === 2 && root.expired) {
                if (!root.check(root.resolved && root.cancelled && !live.connected && live._pendingCount === 0, "disable cleanup")) return;
                if (!root.check(offline._pendingCount === 0 && offline._queue.length === 0 && !offline._expiryTimer.running && !offline._reconnectTimer.running, "offline expiry and idle")) return;
                console.log("NOVA_JSONL_OK"); Qt.quit();
            }
        }
    }
}
''')
        environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                           XDG_RUNTIME_DIR=temporary, QS_DISABLE_CRASH_HANDLER="1")
        try:
            result = subprocess.run([sys.argv[1], "-p", str(directory / "shell.qml")],
                                    env=environment, capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
            worker.join(timeout=6)
            if result.returncode or "NOVA_JSONL_OK" not in output or any(error in output for error in
                    ("NOVA_JSONL_FAILED", "TypeError", "ReferenceError", "Cannot assign", "Failed to load configuration")):
                raise RuntimeError(output)
            if failures or worker.is_alive() or received.count(b"\n") != 2:
                raise RuntimeError(f"Unexpected socket traffic or shutdown: {failures}, {len(received)} bytes")
            print("Actual Quickshell: bounded requests, malformed replies, disable, offline expiry and idle timers: OK")
        finally:
            server.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
