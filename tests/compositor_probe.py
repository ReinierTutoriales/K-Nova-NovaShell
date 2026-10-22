#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""compositor.capabilities contra compositores reales.

Uso: compositor_probe.py <ruta a nova-platform>

1. Compositor colgado: un socket que acepta la conexión Wayland y nunca
   responde. El daemon debe contestar available=false dentro del plazo
   (500 ms) y seguir atendiendo.
2. Weston headless (si está instalado): available=true, wl_compositor en la
   lista y resultado cacheado en la segunda petición.
"""

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
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
    weston_compositor(sys.argv[1])
    print(f"\n{len(FAILURES)} fallo(s)")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
