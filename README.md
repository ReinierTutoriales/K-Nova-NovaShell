<h1 align="center">K-Nova · NovaShell</h1>

<p align="center"><strong>Un escritorio Quickshell para KDE Plasma 6 — ligero, estable y sin root.</strong></p>

<p align="center"><code>Plasma 6 / Wayland</code> &nbsp; <code>Quickshell 0.3.x</code> &nbsp; <code>Qt 6.6+</code> &nbsp; <code>GPL-3.0-or-later</code></p>

> **Estado: base inicial (`0.1.0-dev`).** Hay daemon IPC, barra superior con
> reloj y estado del servicio, instalador y CI. Dock, lanzador, notificaciones
> y centro de control están en la [hoja de ruta](docs/HOJA-DE-RUTA.md).

---

## Principios de NovaShell

NovaShell desarrolla una experiencia de escritorio para KDE Plasma 6 con
Quickshell, una interfaz modular y servicios de usuario.

- Instalación en `~/.local` y `~/.config`, sin root.
- Núcleo basado en QML, Wayland y un daemon C++/Qt6.
- Componentes QML de hasta 400 líneas, verificados por CI.
- Acceso al sistema mediante un [contrato IPC versionado](docs/CONTRATO-IPC-v1.md)
  y un socket privado con permisos `0600`.
- Presupuesto de recursos y arranque mediante systemd de usuario.

## Arquitectura

```text
Quickshell (QML)  ──JSONL/Unix socket 0600──►  nova-platform (C++/Qt6)  ──►  sistema
 barra, dock…          contrato IPC v1           operaciones acotadas
```

Detalle en [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).

## Requisitos

- KDE Plasma 6 en sesión **Wayland**.
- [Quickshell](https://quickshell.org) **0.3.x** (comando `qs`).
- Para compilar: CMake ≥ 3.21, Ninja, compilador C++20 y Qt 6 (Core, Network).

Dependencias de compilación por distribución (esto sí usa el gestor de
paquetes de tu sistema; NovaShell en sí nunca pide root):

| Distribución | Paquetes |
| :--- | :--- |
| Arch / CachyOS | `sudo pacman -S --needed cmake ninja gcc qt6-base` |
| Fedora 44 | `sudo dnf install cmake ninja-build gcc-c++ qt6-qtbase-devel` |
| Debian 13 / Ubuntu 26.04 | `sudo apt install cmake ninja-build g++ qt6-base-dev` |
| NixOS | Flake pendiente (hoja de ruta). |

Quickshell no está en todos los repositorios oficiales: instálalo según su
[guía oficial](https://quickshell.org/docs/guide/install-setup/).

## Empezar

```sh
git clone https://github.com/ReinierTutoriales/K-Nova-NovaShell.git
cd K-Nova-NovaShell
./tools/novactl doctor     # comprueba sesión, Plasma, Quickshell y herramientas
./tools/novactl install    # compila e instala en tu usuario
./tools/novactl start      # arranca daemon + shell
./tools/novactl enable     # opcional: arrancar al iniciar sesión
```

Otras órdenes: `stop`, `restart`, `status`, `logs`, `dev`, `version`,
`uninstall [--purge]`. NovaShell **convive** con el panel de Plasma; no
reemplaza `plasmashell` en esta fase.

## Desarrollo

Ver [docs/DESARROLLO.md](docs/DESARROLLO.md). Resumen:

```sh
cmake -S . -B build -G Ninja -DNOVA_WERROR=ON
cmake --build build && ctest --test-dir build --output-on-failure
python3 tools/check-sources.py        # reglas de arquitectura
./tools/novactl dev                   # shell desde las fuentes, recarga en caliente
```

El repositorio incluye skills, agentes y reglas (`AGENTS.md`, `.claude/skills/`, `.cursor/rules/`) para que los asistentes de código produzcan cambios eficientes y de alta calidad, siempre verificados y sin atribución de IA.

## Licencia

[GPL-3.0-or-later](LICENSE).
