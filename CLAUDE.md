# NovaShell — contexto para asistentes de código

Shell de escritorio Quickshell 0.3.x para KDE Plasma 6 Wayland. Lee primero
[docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) y [docs/CONTRATO-IPC-v1.md](docs/CONTRATO-IPC-v1.md).

## Reglas

- `shell/` es solo presentación. **Nunca** `Process {}`, `execDetached()` ni
  comandos del sistema desde QML: añade una operación acotada al daemon.
- Toda operación nueva se documenta en `docs/CONTRATO-IPC-v1.md` en el mismo
  commit (el test `ipc_smoke` falla si no coincide).
- QML ≤ 400 líneas por archivo; colores, radios y tiempos solo desde `Theme`.
- Nada de root: no añadir `sudo` a `novactl` ni escribir fuera de `$HOME`.
- Nada de plugins KWin nativos en el núcleo.
- Cabecera `SPDX-License-Identifier: GPL-3.0-or-later` en todo archivo de código.
- **Autoría:** todos los commits van a nombre de ReinierTutoriales. Prohibido
  firmar como IA: nada de `Co-Authored-By`, `Claude-Session`, "Generated with"
  ni autor/committer de un asistente, y nada de ramas con nombre de asistente
  (`claude/…` etc.).
- Trabajo paso a paso según [docs/HOJA-DE-RUTA.md](docs/HOJA-DE-RUTA.md); no
  adelantar fases.

## Verificación antes de entregar

```sh
cmake -S . -B build -G Ninja -DNOVA_WERROR=ON && cmake --build build
ctest --test-dir build --output-on-failure        # como usuario normal
python3 tools/check-sources.py
shellcheck -x tools/novactl
```

Las pruebas visuales del shell requieren una sesión Plasma 6 Wayland real (VM).
