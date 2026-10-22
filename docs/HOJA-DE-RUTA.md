# Hoja de ruta

Paso a paso: cada fase debe quedar estable (tests + CI en verde y probada en
Plasma real) antes de empezar la siguiente.

## Fase 0 — Base ✅ (esta versión)

- Daemon `nova-platform` con contrato IPC v1, socket seguro y tests.
- Shell Quickshell mínimo: barra por pantalla, reloj, estado del servicio.
- Sistema de tokens de diseño (`Theme`) con claro/oscuro y `reduceMotion`.
- `novactl` sin root, units systemd de usuario, CI con reglas de arquitectura.

## Fase 1 — Barra completa

Base visual transversal disponible: iconos vectoriales y cuatro apariencias,
materiales, controles accesibles, galería y exportación freedesktop.
Ver [Apariencia](APARIENCIA.md). Esto no da por completados el dock,
las integraciones de la barra ni la aceptación en una sesión Plasma real.

- Bandeja del sistema (StatusNotifierItem, nativo en Quickshell).
- Volumen y dispositivo de salida (PipeWire, nativo en Quickshell).
- Red y Bluetooth vía daemon (NetworkManager / BlueZ por DBus).
- Batería y brillo.
- Medición de RAM/CPU del shell en reposo; fijar presupuesto (objetivo a validar).

## Fase 2 — Dock

- Apps fijadas y ventanas abiertas (protocolo de toplevels de Wayland).
- Lanzar apps por ID de escritorio a través del daemon (`application.launch`),
  nunca con un comando arbitrario.
- Ocultación automática y animaciones con `Theme.motion`.

## Fase 3 — Lanzador y búsqueda

- Lanzador a pantalla completa y búsqueda rápida de apps.
- Navegación completa por teclado desde el diseño inicial.

## Fase 4 — Notificaciones y centro de control

- Servidor de notificaciones con historial y "No molestar".
- Centro de control: Wi-Fi, Bluetooth, volumen, brillo, capturas.

## Fase 5 — Apariencia avanzada

- Materiales (vidrio, esmerilado, tonal) como juegos de tokens intercambiables.
- Desenfoque de fondo usando el protocolo de blur de KWin desde la ventana,
  sin plugin nativo (verificar soporte en Quickshell 0.3.x antes de implementar).
- Paquetes de temas.

## Fase 6 — Distribución

- Flake de NixOS, PKGBUILD (AUR), spec de Fedora/COPR.
- Releases firmadas por tag; `novactl update` con selección de versión.
- Opción de sustituir `plasmashell` de forma reversible.

## Pendientes de verificación técnica

- Validar Plasma 6.8 Wayland con Quickshell 0.3.2 y Qt 6.12 en una sesión real.
- Lint QML completo en CI con Quickshell instalado (hoy: sintaxis + reglas).
