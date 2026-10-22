# Hoja de ruta

Versión publicada: **0.3.0** (pre-release). Ver [cambios](../CHANGELOG.md).

Estados: ✅ implementado y probado con Quickshell 0.3.2 real en un compositor
Wayland headless · 🟡 implementado, falta validar en Plasma 6.8 real ·
⬜ pendiente. Nada se da por terminado sin una sesión Plasma real.

## Fase 0 — Base ✅

- Daemon `nova-platform` con contrato IPC v1, socket seguro y tests (ASan/UBSan en CI).
- Tokens de diseño (`Theme`), claro/oscuro, accesibilidad.
- `novactl` sin root, units systemd de usuario, CI con reglas de arquitectura.

## Fase 1 — Barra 🟡

- ✅ Barra por pantalla con lanzador, apariencia, reloj y estado del servicio.
- ✅ Indicadores de red, Bluetooth, volumen y batería (servicios nativos de
  Quickshell; cada uno se oculta si el equipo no lo tiene).
- ✅ Bandeja del sistema (StatusNotifierItem).
- 🟡 Valores reales de PipeWire/NetworkManager/UPower/BlueZ: el entorno de
  prueba no tiene esos servicios.
- 🟡 Reposo medido sin GPU (0,10 % CPU con widgets, daemon 0 % y 17,5 MiB); falta medir en Plasma real con GPU.

## Fase 2 — Dock ✅ / 🟡

- ✅ Apps fijadas con iconos del tema del sistema (biblioteca MacTahoe).
- ✅ Lanzar por ID `.desktop` vía daemon, menú contextual, ampliación, autoocultación.
- 🟡 Ventanas abiertas y agrupación: requiere el puente KWin (script) en Plasma.

## Fase 3 — Lanzador y búsqueda ✅

- ✅ Lanzador con búsqueda por relevancia sin acentos (índice por catálogo), teclado completo, fijar/quitar del dock; 18 ms por pulsación con 300 apps ([medida](OPTIMIZACION.md#lanzador-y-búsqueda)).
- ⬜ Navegación completa por teclado revisada con lector de pantalla.

## Fase 4 — Notificaciones y centro de control 🟡

- ✅ Centro de control: Wi-Fi, Bluetooth, volumen, brillo, No molestar,
  capturas y acciones de sesión.
- 🟡 Servidor de notificaciones con historial (opcional en Ajustes).

## Fase 5 — Apariencia y escritorio 🟡

- ✅ Materiales Cristal / Esmerilado / Sólido con brillo especular y canto de luz.
- ✅ Blur solo si el compositor anuncia `ext-background-effect-v1` (detección en el daemon).
- ✅ Ajustes con barra lateral y selectores con nombres traducidos.
- ✅ Campos de búsqueda y contraseña adaptados al tema; prueba de cambio
  claro/oscuro y navegación por teclado del lanzador con Qt real.
- ✅ Widgets de escritorio: reloj analógico, uso del sistema y calendario.
- 🟡 Aspecto del blur sobre KWin 6.8 (el compositor de prueba no lo soporta).
- ⬜ Widget del tiempo: necesita una operación de red acotada en el daemon.
- ⬜ Paquetes de temas.

## Fase 5b — Sesión 🟡

Ver [sesión](SESION.md).

- 🟡 Splash NovaShell (look-and-feel por usuario) y fondo claro/oscuro: carga
  probada con Qt real desde la instalación; falta `ksplashqml` en Plasma.
- 🟡 Fondo NovaShell en la pantalla de bloqueo. La interfaz de bloqueo no se
  reemplaza: KWin no ofrece `ext-session-lock-v1` y `kscreenlocker` la toma
  del paquete de shell de Plasma.
- ✅ Bienvenida de primer uso: probada con Quickshell y el daemon reales.
- 🟡 Tema SDDM de inicio de sesión: probado con la API simulada de SDDM 0.21
  y OpenGL; falta `sddm-greeter-qt6` real. Plasma Login Manager no admite temas.

## Fase 6 — Distribución 🟡

- ✅ Releases por etiqueta `vX.Y.Z` con notas de cambios ([proceso](LANZAMIENTO.md)).
- ⬜ Firma de etiquetas y `novactl update` con selección de versión.
- ⬜ Flake de NixOS, PKGBUILD (AUR), spec de Fedora/COPR.
- Opción de sustituir `plasmashell` de forma reversible.

## Pendientes de verificación técnica

- ✅ Progreso real del catálogo, sin animación oculta y con movimiento reducido.
- ✅ Carpetas e iconos: 440 renderizados Qt; variante de Dolphin de 16 px sin
  filtros subpíxel problemáticos, conservando el vector completo a otros tamaños.
- ⬜ Comparación visual completa de iconos y carpetas frente a macOS 27.
- ✅ Carpetas propias en vidrio monocromo (Golden Gate): 13 roles y 73
  sinónimos, cuatro apariencias y símbolos ópticos a 16 px. Iconos de
  aplicaciones: MacTahoe.
- 🟡 Aspecto nativo aplicado al instalar (iconos, paleta, acento neutro,
  Dolphin, transiciones KWin, sesión), reversible: probado con KConfig
  simulado de extremo a extremo; falta Plasma 6.8 real.
- ⬜ Estilo Qt Widgets para materiales de Dolphin y progreso KIO/Plasma.

- Sesión real Plasma 6.8 Wayland con Quickshell 0.3.2 y Qt 6.12: blur, GPU,
  consumo en reposo, puente KWin y servicios del sistema.
