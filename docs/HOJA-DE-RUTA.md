# Hoja de ruta

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
- ⬜ Presupuesto medido de RAM/CPU del shell en reposo en Plasma real.

## Fase 2 — Dock ✅ / 🟡

- ✅ Apps fijadas con iconos del tema del sistema (biblioteca MacTahoe).
- ✅ Lanzar por ID `.desktop` vía daemon, menú contextual, ampliación, autoocultación.
- 🟡 Ventanas abiertas y agrupación: requiere el puente KWin (script) en Plasma.

## Fase 3 — Lanzador y búsqueda ✅

- ✅ Lanzador con búsqueda sin acentos, fijar/quitar del dock.
- ⬜ Navegación completa por teclado revisada con lector de pantalla.

## Fase 4 — Notificaciones y centro de control 🟡

- ✅ Centro de control: Wi-Fi, Bluetooth, volumen, brillo, No molestar,
  capturas y acciones de sesión.
- 🟡 Servidor de notificaciones con historial (opcional en Ajustes).

## Fase 5 — Apariencia y escritorio 🟡

- ✅ Materiales Cristal / Esmerilado / Sólido con brillo especular y canto de luz.
- ✅ Blur solo si el compositor anuncia `ext-background-effect-v1` (detección en el daemon).
- ✅ Ajustes con barra lateral y selectores con nombres traducidos.
- ✅ Widgets de escritorio: reloj analógico, uso del sistema y calendario.
- 🟡 Aspecto del blur sobre KWin 6.8 (el compositor de prueba no lo soporta).
- ⬜ Widget del tiempo: necesita una operación de red acotada en el daemon.
- ⬜ Paquetes de temas.

## Fase 6 — Distribución ⬜

- Flake de NixOS, PKGBUILD (AUR), spec de Fedora/COPR.
- Releases firmadas por tag; `novactl update` con selección de versión.
- Opción de sustituir `plasmashell` de forma reversible.

## Pendientes de verificación técnica

- Sesión real Plasma 6.8 Wayland con Quickshell 0.3.2 y Qt 6.12: blur, GPU,
  consumo en reposo, puente KWin y servicios del sistema.
