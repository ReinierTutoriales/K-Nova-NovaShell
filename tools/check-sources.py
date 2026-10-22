#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Reglas de arquitectura de NovaShell que el CI hace cumplir.

1. Ningún archivo QML supera MAX_QML_LINES.
2. El QML no ejecuta procesos: Process, execDetached y similares están
   prohibidos. Todo acceso al sistema pasa por nova-platform (contrato IPC).
3. Todo archivo de código lleva cabecera SPDX.
4. (opcional) Cada QML se analiza con qmlformat para detectar errores de
   sintaxis, si qmlformat está disponible.

Uso: check-sources.py [--qmlformat RUTA]
"""

import argparse
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAX_QML_LINES = 400
CODE_SUFFIXES = {".qml", ".cpp", ".h", ".py", ".mjs", ".js"}
SKIP_DIRS = {".git", "build"}

# Patrones que permitirían a la UI saltarse el daemon.
FORBIDDEN_QML = [
    (re.compile(r"\bProcess\s*\{"), "Process {} (la UI no ejecuta procesos)"),
    (re.compile(r"\bexecDetached\s*\("), "execDetached() (la UI no ejecuta procesos)"),
    (re.compile(r"\bQt\.openUrlExternally\s*\(\s*[\"']file:"), "abrir archivos directamente; usa el daemon"),
]


def source_files():
    for path in ROOT.rglob("*"):
        if path.is_file() and not (set(path.relative_to(ROOT).parts) & SKIP_DIRS):
            yield path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qmlformat", help="ruta a qmlformat para comprobar sintaxis")
    args = parser.parse_args()

    qmlformat = args.qmlformat or shutil.which("qmlformat") or shutil.which("qmlformat6")
    problems = []

    for path in sorted(source_files()):
        rel = path.relative_to(ROOT)
        if path.suffix not in CODE_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8")

        if "SPDX-License-Identifier:" not in "\n".join(text.splitlines()[:5]):
            problems.append(f"{rel}: falta la cabecera SPDX-License-Identifier")

        if path.suffix != ".qml":
            continue

        lines = text.count("\n") + 1
        if lines > MAX_QML_LINES:
            problems.append(f"{rel}: {lines} líneas (máximo {MAX_QML_LINES}); divídelo en componentes")

        for number, line in enumerate(text.splitlines(), 1):
            code = line.split("//", 1)[0]
            for pattern, why in FORBIDDEN_QML:
                if pattern.search(code):
                    problems.append(f"{rel}:{number}: prohibido {why}")

        if qmlformat:
            result = subprocess.run([qmlformat, str(path)], capture_output=True, text=True)
            if result.returncode != 0:
                problems.append(f"{rel}: error de sintaxis QML\n{result.stderr.strip()}")

    if not qmlformat:
        print("aviso: qmlformat no encontrado; se omite la comprobación de sintaxis QML")

    for problem in problems:
        print(f"FAIL {problem}")
    print(f"{len(problems)} problema(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
