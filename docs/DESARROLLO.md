# Desarrollo

## Compilar y probar

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DNOVA_WERROR=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

- `protocol`: tests unitarios (QtTest) del parseo, límites y router.
- `ipc_smoke`: arranca el daemon real con un socket temporal y verifica
  permisos, respuestas, límites, segunda instancia, cierre por SIGTERM y que
  `platform.capabilities` coincide con `docs/CONTRATO-IPC-v1.md`.
  Se omite si se ejecuta como root (el daemon lo rechaza por diseño).

Reglas de arquitectura (tamaño de QML, prohibición de procesos en la UI,
cabeceras SPDX, sintaxis QML):

```sh
python3 tools/check-sources.py --qmlformat "$(command -v qmlformat || echo /usr/lib/qt6/bin/qmlformat)"
shellcheck -x tools/novactl
```

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

## Dónde probar

Las pruebas visuales del shell se hacen en una sesión Plasma 6 Wayland, idealmente
en una VM. El daemon y las reglas se prueban en cualquier Linux (y en el CI).
