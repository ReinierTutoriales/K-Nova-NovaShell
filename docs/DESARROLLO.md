# Desarrollo

## Compilar y probar

Objetivo estable: Qt 6.12.0+, Quickshell 0.3.2+ y Plasma 6.8 Wayland.
Mínimos para usuarios: `packaging/runtime.env` (`NOVA_MIN_QT`, `NOVA_MIN_QUICKSHELL`,
`NOVA_MIN_PLASMA`). El CI compila y prueba con la Qt fijada en
`tests/requirements-ci.txt`, que sigue a la última estable.
Para pruebas visuales: `python3 -m pip install -r tests/requirements-ci.txt`.
Quickshell debe estar compilado para la misma versión exacta de Qt en ejecución;
`novactl doctor` comprueba ese dato sin mostrar el diagnóstico completo del entorno.

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DNOVA_WERROR=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

- `protocol`: tests unitarios (QtTest) del parseo, límites y router.
- `appearance`: contratos de iconos, materiales y accesibilidad (Node).
- `icon_library`: integridad del paquete completo de recursos y enlaces.
- `ipc_smoke`: arranca el daemon real con un socket temporal y verifica
  permisos, respuestas, límites, segunda instancia, cierre por SIGTERM y que
  `platform.capabilities` coincide con `docs/CONTRATO-IPC-v1.md`.
  Se omite si se ejecuta como root (el daemon lo rechaza por diseño).
- `desktop_profile`, `sddm_install`, `check_updates`: perfil nativo, instalador
  del tema SDDM y detección de versiones.

Pruebas fuera de `ctest` (las ejecuta el CI; ver `.github/workflows/ci.yml`):

| Prueba | Qué cubre |
| :--- | :--- |
| `tests/quickshell_smoke.py <qs> <daemon>` | Quickshell real + daemon: catálogo, preferencias, vistas y bienvenida. |
| `tests/install_smoke.py` | `novactl install`/`uninstall` en un HOME vacío: manifiesto, servicios, paquetes de sesión y que no queden restos. Compila en una carpeta propia (1–2 minutos). |
| `tests/session_smoke.py build` | Splash y tema SDDM cargados desde `cmake --install`, con la API de SDDM 0.21 simulada. |
| `tests/appearance_smoke.py`, `tests/desktop_smoke.py` | Renderizado Qt de apariencia, iconos y vistas. |

Las de renderizado necesitan `python3 -m pip install -r tests/requirements-ci.txt`.

Reglas de arquitectura (tamaño de QML, prohibición de procesos en la UI,
cabeceras SPDX, sintaxis QML):

```sh
python3 tools/check-sources.py --qmlformat "$(command -v qmlformat || echo /usr/lib/qt6/bin/qmlformat)"
shellcheck -x tools/novactl packaging/sddm/install-theme.sh
```

Los fondos se regeneran con `python3 tools/render-wallpapers.py` (numpy y
Pillow) y los temas de iconos con `node tools/export-icons.mjs assets/icons`;
el CI comprueba que el resultado versionado coincide.

## Ejecutar el shell desde las fuentes

```sh
./tools/novactl stop   # si el servicio instalado está activo
./tools/novactl dev    # qs -p shell/ con recarga en caliente
```

`dev` usa el daemon instalado si su socket existe; si no, arranca el de
`build/` y lo detiene al salir.

## Probar el daemon a mano

```sh
./build/daemon/nova-platform --socket /tmp/nova-test/platform.sock &
printf '%s\n' '{"version":1,"requestId":"1","operation":"platform.capabilities"}' \
  | socat - UNIX-CONNECT:/tmp/nova-test/platform.sock
```

## Añadir una operación al daemon

1. Escribe el manejador y regístralo en `Router::makeDefault()` (o en un
   módulo propio que lo registre).
2. Añade la fila a la tabla de `docs/CONTRATO-IPC-v1.md` (el test lo exige).
3. Si es una lectura idempotente, añádela a `readOperations` en
   `shell/nova/services/Platform.qml`.
4. Tests: unitario del manejador + caso en `ipc_smoke.py` si toca el socket.

## Añadir un módulo QML

- Carpeta en `shell/nova/<módulo>/` con su `qmldir` (`module qs.nova.<módulo>`).
- Componentes pequeños (≤ 400 líneas); colores y tiempos desde `Theme`.
- Datos del sistema solo a través de `Platform`.

## Asistentes de código (IA)

El repositorio incluye instrucciones y skills para agentes de código:

- `AGENTS.md` y `CLAUDE.md` en la raíz: reglas, comandos y límites.
- Skills en `.claude/skills/` (`qml-development`, `ipc-operations`, `code-efficiency`, `commit-hygiene`).
- Agente `code-optimizer` en `.claude/agents/`.
- Reglas para Cursor en `.cursor/rules/`.
- Workflow que bloquea atribución de IA en PRs.

Los agentes deben seguir estas reglas, verificar siempre y **nunca** firmar commits ni crear ramas con nombres de asistentes. Todo el trabajo queda a nombre de ReinierTutoriales.

## Dónde probar

Las pruebas visuales del shell se hacen en una sesión Plasma 6 Wayland, idealmente
en una VM. El daemon y las reglas se prueban en cualquier Linux (y en el CI).
