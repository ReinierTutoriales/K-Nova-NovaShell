#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""compositor.capabilities contra compositores reales.

Uso: compositor_probe.py <ruta a nova-platform>

1. Compositor colgado: un socket que acepta la conexión Wayland y nunca
   responde. El daemon debe contestar available=false dentro del plazo
   (500 ms) y seguir atendiendo.
2. Compositor mínimo en Python (sin dependencias): habla el protocolo de
   cable de Wayland, anuncia globals conocidos y verifica la detección
   positiva y negativa de ext-background-effect-v1 y la caché.
3. Weston headless (solo si está instalado localmente; el CI no lo instala
   porque arrastra cientos de MB de dependencias).
"""

import json
import os
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time

FAILURES = []


def check(condition, message):
    print(("ok   " if condition else "FAIL ") + message)
    if not condition:
        FAILURES.append(message)


def wait_for(path, timeout=10.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if os.path.exists(path):
            return True
        time.sleep(0.05)
    return False


def request(sock_path, operation):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(5)
        client.connect(sock_path)
        client.sendall((json.dumps({"version": 1, "requestId": "1",
                                    "operation": operation}) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = client.recv(65536)
            if not chunk:
                break
            data += chunk
    return json.loads(data)


def run_daemon(daemon, runtime, display):
    env = dict(os.environ, XDG_RUNTIME_DIR=runtime, WAYLAND_DISPLAY=display)
    sock_path = os.path.join(runtime, "novashell", "platform.sock")
    process = subprocess.Popen([daemon], env=env)
    if not wait_for(sock_path):
        process.kill()
        raise SystemExit("el daemon no creó su socket")
    return process, sock_path


def stop(process):
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
    check(process.returncode == 0, f"el daemon termina limpio (código {process.returncode})")


def hung_compositor(daemon):
    with tempfile.TemporaryDirectory() as runtime:
        os.chmod(runtime, 0o700)
        fake = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        fake.bind(os.path.join(runtime, "wayland-hung"))
        fake.listen(4)  # acepta en el backlog y nunca lee ni responde
        process, sock_path = run_daemon(daemon, runtime, "wayland-hung")
        try:
            started = time.monotonic()
            reply = request(sock_path, "compositor.capabilities")
            elapsed = time.monotonic() - started
            check(reply["ok"] and reply["result"]["available"] is False,
                  "compositor colgado: available=false")
            check(0.4 <= elapsed < 1.5, f"compositor colgado: respuesta acotada ({elapsed:.2f}s)")
            check(request(sock_path, "platform.ping")["ok"], "el daemon sigue atendiendo")
        finally:
            stop(process)
            fake.close()


class FakeCompositor:
    """Servidor Wayland mínimo: responde a wl_display.get_registry y sync.

    Formato de cable: cabecera (id de objeto u32, tamaño<<16 | opcode u32) y
    argumentos alineados a 4 bytes; las cadenas llevan longitud con NUL.
    """

    def __init__(self, path, interfaces):
        self.interfaces = interfaces
        self.connections = 0
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(path)
        self.server.listen(4)
        self.thread = threading.Thread(target=self._serve, daemon=True)
        self.thread.start()

    @staticmethod
    def _message(object_id, opcode, payload):
        return struct.pack("<II", object_id, ((8 + len(payload)) << 16) | opcode) + payload

    @staticmethod
    def _string(text):
        data = text.encode() + b"\0"
        return struct.pack("<I", len(data)) + data + b"\0" * (-len(data) % 4)

    def _serve(self):
        while True:
            try:
                connection, _ = self.server.accept()
            except OSError:
                return
            self.connections += 1
            with connection:
                buffer = b""
                while True:
                    chunk = connection.recv(4096)
                    if not chunk:
                        break
                    buffer += chunk
                    while len(buffer) >= 8:
                        object_id, word = struct.unpack_from("<II", buffer)
                        size, opcode = word >> 16, word & 0xFFFF
                        if len(buffer) < size:
                            break
                        args, buffer = buffer[8:size], buffer[size:]
                        if object_id != 1:
                            continue  # solo wl_display tiene peticiones aquí
                        (new_id,) = struct.unpack_from("<I", args)
                        if opcode == 1:  # get_registry -> un global por interfaz
                            for name, interface in enumerate(self.interfaces, 1):
                                connection.sendall(self._message(
                                    new_id, 0, struct.pack("<I", name)
                                    + self._string(interface) + struct.pack("<I", 1)))
                        elif opcode == 0:  # sync -> wl_callback.done + delete_id
                            connection.sendall(self._message(new_id, 0, struct.pack("<I", 1))
                                               + self._message(1, 1, struct.pack("<I", new_id)))

    def close(self):
        self.server.close()


def fake_compositor(daemon):
    cases = [
        ("con ext-background-effect-v1",
         ["wl_compositor", "zwlr_layer_shell_v1", "ext_background_effect_manager_v1",
          "org_kde_kwin_blur_manager", "wp_fractional_scale_manager_v1", "wl_compositor"],
         {"backgroundEffect": True, "kdeBlur": True, "layerShell": True, "fractionalScale": True}),
        ("sin protocolo de blur",
         ["wl_compositor", "wl_shm", "xdg_wm_base"],
         {"backgroundEffect": False, "kdeBlur": False, "layerShell": False, "fractionalScale": False}),
    ]
    for label, interfaces, expected in cases:
        with tempfile.TemporaryDirectory() as runtime:
            os.chmod(runtime, 0o700)
            fake = FakeCompositor(os.path.join(runtime, "wayland-fake"), interfaces)
            process, sock_path = run_daemon(daemon, runtime, "wayland-fake")
            try:
                result = request(sock_path, "compositor.capabilities")["result"]
                check(result["available"] is True, f"{label}: available=true")
                check({key: result[key] for key in expected} == expected,
                      f"{label}: indicadores correctos")
                check(result["interfaces"] == sorted(set(interfaces)),
                      f"{label}: interfaces ordenadas y sin duplicados")
                again = request(sock_path, "compositor.capabilities")["result"]
                check(again == result and fake.connections == 1,
                      f"{label}: segunda petición servida desde la caché")
            finally:
                stop(process)
                fake.close()


def weston_compositor(daemon):
    weston = shutil.which("weston")
    if not weston:
        print("omitido: weston no está instalado")
        return
    with tempfile.TemporaryDirectory() as runtime:
        os.chmod(runtime, 0o700)
        env = dict(os.environ, XDG_RUNTIME_DIR=runtime)
        env.pop("WAYLAND_DISPLAY", None)
        compositor = subprocess.Popen(
            [weston, "--backend=headless", "--socket=wayland-nova-test", "--idle-time=0"],
            env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            if not wait_for(os.path.join(runtime, "wayland-nova-test")):
                check(False, "weston headless arranca")
                return
            process, sock_path = run_daemon(daemon, runtime, "wayland-nova-test")
            try:
                result = request(sock_path, "compositor.capabilities")["result"]
                check(result["available"] is True, "weston: available=true")
                check("wl_compositor" in result["interfaces"], "weston: anuncia wl_compositor")
                check(result["interfaces"] == sorted(set(result["interfaces"])),
                      "weston: interfaces ordenadas y sin duplicados")
                check(all(isinstance(result[key], bool) for key in
                          ("backgroundEffect", "kdeBlur", "layerShell", "fractionalScale")),
                      "weston: indicadores booleanos")
                compositor.terminate()
                compositor.wait(timeout=5)
                again = request(sock_path, "compositor.capabilities")["result"]
                check(again == result, "resultado cacheado tras el primer sondeo correcto")
            finally:
                stop(process)
        finally:
            if compositor.poll() is None:
                compositor.kill()
                compositor.wait()


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    if os.getuid() == 0:
        print("omitido: el daemon se niega a correr como root (por diseño)")
        return 77
    hung_compositor(sys.argv[1])
    fake_compositor(sys.argv[1])
    weston_compositor(sys.argv[1])
    print(f"\n{len(FAILURES)} fallo(s)")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
