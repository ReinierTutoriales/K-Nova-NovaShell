#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Prueba de extremo a extremo del daemon nova-platform.

Uso: ipc_smoke.py <ruta a nova-platform> <ruta a CONTRATO-IPC-v1.md>

Verifica permisos del socket, respuestas del protocolo, que la lista de
operaciones coincide con el contrato documentado, que una segunda
instancia no roba el socket y que SIGTERM cierra limpio.
"""

import json
import os
import re
import signal
import socket
import stat
import subprocess
import sys
import tempfile
import time

FAILURES = []


def check(condition, message):
    if condition:
        print(f"ok   {message}")
    else:
        print(f"FAIL {message}")
        FAILURES.append(message)


def documented_operations(contract_path):
    with open(contract_path, encoding="utf-8") as handle:
        text = handle.read()
    match = re.search(r"<!-- operaciones:inicio -->(.*?)<!-- operaciones:fin -->", text, re.S)
    if not match:
        raise SystemExit("el contrato no tiene el bloque <!-- operaciones:inicio/fin -->")
    return sorted(set(re.findall(r"^\|\s*`([a-z][a-z0-9.-]+)`", match.group(1), re.M)))


def wait_for_socket(path, process, timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if os.path.exists(path):
            return True
        if process.poll() is not None:
            return False
        time.sleep(0.05)
    return False


class Client:
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(3)
        self.sock.connect(path)
        self.buffer = b""

    def send_raw(self, data):
        self.sock.sendall(data)

    def request(self, request_id, operation, payload=None):
        message = {"version": 1, "requestId": request_id, "operation": operation}
        if payload is not None:
            message["payload"] = payload
        self.send_raw((json.dumps(message) + "\n").encode())
        return self.read_line()

    def read_line(self):
        while b"\n" not in self.buffer:
            chunk = self.sock.recv(65536)
            if not chunk:
                raise ConnectionError("el daemon cerró la conexión")
            self.buffer += chunk
        line, self.buffer = self.buffer.split(b"\n", 1)
        return json.loads(line)

    def close(self):
        self.sock.close()


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    daemon, contract = sys.argv[1], sys.argv[2]
    if os.getuid() == 0:
        print("omitido: el daemon se niega a correr como root (por diseño)")
        return 77

    with tempfile.TemporaryDirectory() as tmp:
        run_dir = os.path.join(tmp, "novashell")
        sock_path = os.path.join(run_dir, "platform.sock")
        process = subprocess.Popen([daemon, "--socket", sock_path])
        try:
            check(wait_for_socket(sock_path, process), "el daemon crea el socket")
            if FAILURES:
                return 1

            check(stat.S_IMODE(os.stat(run_dir).st_mode) == 0o700, "directorio del socket en 0700")
            check(stat.S_IMODE(os.stat(sock_path).st_mode) == 0o600, "socket en 0600")

            client = Client(sock_path)
            reply = client.request("1", "platform.ping")
            check(reply == {"version": 1, "requestId": "1", "ok": True, "result": {"ready": True}},
                  "platform.ping responde ready")

            reply = client.request("2", "platform.version")
            check(reply.get("ok") and reply["result"].get("protocol") == 1, "platform.version informa protocolo 1")

            reply = client.request("3", "platform.capabilities")
            live = sorted(reply.get("result", {}).get("operations", []))
            documented = documented_operations(contract)
            check(live == documented,
                  f"capabilities coincide con el contrato (vivo={live}, doc={documented})")

            reply = client.request("4", "system.reboot")
            check(not reply["ok"] and reply["error"]["code"] == "unknown-operation",
                  "operación no registrada se rechaza")

            client.send_raw(b"esto no es json\n")
            reply = client.read_line()
            check(not reply["ok"] and reply["error"]["code"] == "invalid-json", "JSON inválido se rechaza")

            # Dos peticiones en un mismo paquete: ambas deben responderse en orden.
            client.send_raw(b'{"version":1,"requestId":"a","operation":"platform.ping"}\n'
                            b'{"version":1,"requestId":"b","operation":"platform.ping"}\n')
            check([client.read_line()["requestId"], client.read_line()["requestId"]] == ["a", "b"],
                  "varias líneas en un paquete se procesan en orden")
            client.close()

            # Línea gigante sin salto: el daemon corta la conexión, no crece en memoria.
            abuser = Client(sock_path)
            try:
                abuser.send_raw(b"x" * (70 * 1024))
                reply = abuser.read_line()
                check(reply["error"]["code"] == "request-too-large", "línea sobredimensionada se corta")
            except (ConnectionError, OSError):
                check(True, "línea sobredimensionada se corta")
            abuser.close()

            check(process.poll() is None, "el daemon sigue vivo tras entradas inválidas")

            second = subprocess.run([daemon, "--socket", sock_path], capture_output=True, timeout=5)
            check(second.returncode != 0, "una segunda instancia no roba el socket")
            check(Client(sock_path).request("5", "platform.ping")["ok"], "la primera instancia sigue atendiendo")
        finally:
            if process.poll() is None:
                process.send_signal(signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()

        check(process.returncode == 0, "SIGTERM produce salida limpia (código 0)")
        check(not os.path.exists(sock_path), "el socket se elimina al salir")

    print(f"\n{len(FAILURES)} fallo(s)")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
