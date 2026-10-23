# Contrato IPC v1 — `nova-platform`

Este documento es **la fuente de verdad** de lo que el shell puede pedirle al
sistema. Si una operación no está aquí, no existe. El test `ipc_smoke`
compara la tabla de operaciones con lo que el daemon anuncia en
`platform.capabilities` y falla si no coinciden.

## Transporte

- Socket Unix por usuario: `$XDG_RUNTIME_DIR/novashell/platform.sock`.
- Directorio `0700`, socket `0600`, y el daemon verifica con `SO_PEERCRED`
  que el cliente es el mismo UID. **No es una API de red.**
- Mensajes: objetos JSON UTF-8, uno por línea (`\n`). Máximo 64 KiB por línea;
  una línea mayor cierra la conexión.
- Máximo 32 clientes simultáneos.

## Petición

```json
{"version":1,"requestId":"42","operation":"platform.ping","payload":{}}
```

| Campo | Tipo | Regla |
| :--- | :--- | :--- |
| `version` | entero | Debe ser `1`. |
| `requestId` | texto | 1–64 caracteres. Lo elige el cliente; se devuelve tal cual. |
| `operation` | texto | `grupo.accion` en minúsculas (`^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*)+$`). |
| `payload` | objeto | Opcional. |

## Respuesta

```json
{"version":1,"requestId":"42","ok":true,"result":{"ready":true}}
{"version":1,"requestId":"42","ok":false,"error":{"code":"unknown-operation","message":"…","retryable":false}}
```

Si la petición es tan inválida que no se pudo leer `requestId`, la respuesta
lleva `"requestId": null`.

## Eventos (reservado)

Los eventos llegan sin `requestId` y con `event`:

```json
{"version":1,"event":"grupo.nombre","payload":{}}
```

`windows.changed` publica la instantánea de ventanas y escritorios cuando cambia.
Las conexiones lentas se cierran al superar 128 KiB pendientes de escritura.

## Códigos de error

| Código | Significado | `retryable` |
| :--- | :--- | :--- |
| `invalid-json` | La línea no es un objeto JSON. | no |
| `invalid-request` | Falta un campo o tiene un tipo/forma inválida. | no |
| `unsupported-version` | `version` distinta de 1. | no |
| `unknown-operation` | Operación no registrada. | no |
| `request-too-large` | Línea por encima de 64 KiB; se cierra la conexión. | no |
| `internal` | Fallo dentro del manejador; el daemon sigue vivo. | sí |

## Operaciones

<!-- operaciones:inicio -->
| Operación | Payload | Resultado |
| :--- | :--- | :--- |
| `platform.ping` | — | `{"ready": true}` |
| `platform.version` | — | `{"version": "0.3.0", "protocol": 1}` |
| `platform.capabilities` | — | `{"protocol": 1, "operations": ["…"]}` (lista ordenada) |
| `applications.list` | `offset` ≥ 0, `limit` 1–32 | `applications` (`id`, `name`, `genericName`, `icon`, `keywords`), `next`, `total`; páginas de hasta 48 KiB |
| `application.launch` | `id`: identificador `.desktop` instalado | `launched`, `id`; resolución GIO, sin comando arbitrario. Con gestor de usuario systemd, la app corre como unidad propia `app-novashell-<id>-<aleatorio>.service` (`StartTransientUnit` con `gio launch <archivo .desktop>`): no hereda el aislamiento del daemon (`NoNewPrivileges` impediría `sudo`) ni su cgroup (reiniciar el daemon no la cierra). Sin systemd, lanzamiento GIO directo |
| `settings.get` | — | `values`: preferencias validadas del usuario |
| `settings.patch` | Claves permitidas de `Preferences::defaults()` | `values`; escritura atómica, rechazo completo si hay una clave inválida |
| `windows.list` | — | `available`, `windows`, `desktops`, `activeWindow`, `currentDesktop` |
| `window.action` | `action`: activate/minimize/maximize/close/desktop; `id` existente | `accepted`; falla si KWin no está preparado, nunca se encola para más tarde |
| `session.action` | `action`: lock/suspend/logout/reboot/poweroff | `accepted`, `token`; D-Bus tipado, autorización del sistema |
| `screenshot.capture` | — | `launched`; abre el selector de región de Spectacle con argumentos fijos, como unidad propia igual que `application.launch` |
| `wallpaper.set` | `url` de imagen local ≤ 64 MiB; `screen` 0–31 | `accepted`, `token`; API de wallpaper de Plasma |
| `brightness.get` | — | `available`, `displays`; lectura asíncrona y caché de 1 s |
| `brightness.set` | `id` de pantalla enumerada; `percent` entero 1–100 | `accepted`, `token`; API ScreenBrightness de KDE |
| `blur.get` | — | `strength` 1–15 (`[Effect-blur] BlurStrength` de kwinrc; 15 si no está), `writable`. Solo lectura del archivo. |
| `blur.set` | `strength` entero 1–15 | `accepted`, `token`; `kwriteconfig6` con argumentos fijos y recarga del efecto Blur de KWin por D-Bus |
| `system.metrics` | — | `available`, `cpuPercent`, `memoryTotal`, `memoryUsed`; lecturas acotadas de `/proc` |
| `compositor.capabilities` | — | Ver abajo. Solo lectura. |
<!-- operaciones:fin -->

### `compositor.capabilities`

Lista los globals del compositor Wayland de la sesión (`WAYLAND_DISPLAY`) sin
crear superficies. Plazo máximo de 500 ms; el primer resultado correcto se
cachea durante la vida del daemon y un fallo se reintenta en la siguiente
petición.

```json
{"available": true, "backgroundEffect": true, "kdeBlur": true,
 "layerShell": true, "fractionalScale": true, "interfaces": ["wl_compositor", "…"]}
```

| Campo | Significado |
| :--- | :--- |
| `available` | Se pudo leer el registro del compositor. Si es `false`, `reason` explica por qué y todos los indicadores son `false`. |
| `backgroundEffect` | `ext_background_effect_manager_v1`: el protocolo que usa Quickshell `BackgroundEffect`. El shell activa el blur solo si es `true`. |
| `kdeBlur` | `org_kde_kwin_blur_manager` (privado de KDE). Informativo: Quickshell no lo usa. |
| `layerShell` | `zwlr_layer_shell_v1`, necesario para barra y dock. |
| `fractionalScale` | `wp_fractional_scale_manager_v1`. |
| `interfaces` | Nombres de todos los globals, ordenados (máx. 256). |

## Reglas para añadir una operación

1. Debe ser **acotada**: nunca acepta un comando arbitrario, una ruta de
   ejecutable ni un argumento que acabe en un shell.
2. Se documenta aquí **en el mismo commit** que se implementa (el test lo exige).
3. Las de escritura (apagar, borrar, cambiar red…) fallan de inmediato si el
   daemon no está disponible; el cliente no las reintenta solo.
4. Cambios incompatibles = `version: 2`, nunca reinterpretar un campo de v1.
