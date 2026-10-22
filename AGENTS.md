# NovaShell — instrucciones para agentes de código

Shell Quickshell 0.3.2+ para KDE Plasma 6.8+ Wayland y Qt 6.12+. Daemon C++/Qt6 + QML. Nunca root. Sin plugins KWin nativos en el núcleo.

Lee primero `docs/ARQUITECTURA.md`, `docs/CONTRATO-IPC-v1.md` y `docs/HOJA-DE-RUTA.md`.

## Comandos de verificación (ejecutar siempre)

```sh
cmake -S . -B build -G Ninja -DNOVA_WERROR=ON && cmake --build build
ctest --test-dir build --output-on-failure
python3 tools/check-sources.py
shellcheck -x tools/novactl
```

`./tools/novactl doctor` para el entorno. Pruebas visuales requieren sesión Plasma 6 Wayland (idealmente VM).

## Límites innegociables

- QML ≤ 400 líneas por archivo. Colores, radios y duraciones **solo** desde `Theme`.
- La UI **nunca** ejecuta procesos: prohibido `Process {}`, `execDetached()`, comandos de sistema. Todo acceso al sistema pasa por el daemon vía contrato IPC.
- Operaciones nuevas del daemon: acotadas (nunca comando arbitrario ni ruta de ejecutable), documentadas en `docs/CONTRATO-IPC-v1.md` en el **mismo** cambio (el test `ipc_smoke` lo exige).
- Cabecera `SPDX-License-Identifier: GPL-3.0-or-later` en todo archivo de código.
- Sin root: ni daemon ni `novactl`.
- **Autoría:** todos los commits a nombre de ReinierTutoriales. Prohibido firmar como IA (`Co-Authored-By`, emails de servicios de IA, "Generated with", ramas `claude/...` o similares).

## Skills disponibles (cárgalos cuando apliquen)

- `qml-development`: escribir y refactorizar componentes QML eficientes y dentro de límites.
- `ipc-operations`: añadir operaciones acotadas al daemon y contrato.
- `code-efficiency`: optimizar rendimiento, recursos y calidad de código.
- `commit-hygiene`: verificación final, mensajes y prohibición de atribución de IA.

Trabaja paso a paso según la hoja de ruta. No adelantes fases. Preserva el trabajo no relacionado.
