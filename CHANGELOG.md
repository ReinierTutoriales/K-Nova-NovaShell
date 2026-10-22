# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/);
versiones según [SemVer](https://semver.org/lang/es/). Mientras la versión sea
`0.x`, cualquier versión menor puede romper compatibilidad.

## [Sin publicar]

### Añadido
- Splash de inicio de sesión NovaShell (paquete look-and-feel por usuario,
  solo splash) con progreso determinado por etapas de `ksplashqml`.
- Fondo NovaShell claro/oscuro como paquete de Plasma, reproducible con
  `tools/render-wallpapers.py`, y marca propia.
- Tema SDDM (Qt 6) de inicio de sesión con la identidad de NovaShell;
  `novactl login-theme` lo prueba sin root y la instalación de sistema es un
  script aparte que se ejecuta con `sudo`. `novactl doctor` detecta el gestor.
- Símbolos `restart`, `sleep` y `forward`.
- Bienvenida de primer uso (Apple HIG, *Onboarding*): breve, omitible y con
  cambios en vivo; se reabre desde Ajustes o `toggle welcome`.
- Estilo de botón principal (`prominent`) con relleno de acento accesible.
- `desktop-profile` activa también el splash y el fondo de la pantalla de
  bloqueo, de forma reversible; migra los registros de 0.1.0.

- Guía de instalación paso a paso (`docs/INSTALACION.md`) y prueba de
  instalación de extremo a extremo en el CI (`tests/install_smoke.py`).
- Pantalla de inicio de sesión: la fila de usuarios se maneja con teclado
  (Tab y flechas) y Esc borra la contraseña.

### Cambiado
- `novactl install` compila sin las pruebas; `uninstall` borra en lote (de
  ~5 minutos a segundos con la biblioteca de iconos) y también las carpetas
  que quedan vacías, sin salir del prefijo.

### Corregido
- `novactl uninstall --purge` no borraba los ajustes del daemon
  (`~/.config/novashell`).
- Medidas de las pantallas de sesión movidas a `Theme` (sin literales).
- `novactl install` toma la lista de archivos instalados de CMake
  (`install_manifest.txt`) en lugar de enumerarlos a mano.

## [0.1.0] — 2026-10-22 · pre-release

Primera versión funcional. Probada con Quickshell 0.3.2 y Qt 6.12.0 reales
bajo un compositor Wayland headless y en CI; **pendiente de validar en una
sesión Plasma 6.8 real** (blur de KWin, GPU, consumo en reposo y servicios
del sistema), por eso se publica como pre-release.

### Escritorio
- Barra superior por pantalla: lanzador, apariencia, bandeja del sistema,
  indicadores de red, Bluetooth, volumen y batería, y reloj que abre «Hoy».
- Dock con apps fijadas, menú contextual, autoocultación y ampliación opcional.
- Lanzador con búsqueda sin acentos y progreso real del catálogo.
- Centro de control: Wi-Fi, Bluetooth, sonido, brillo, No molestar,
  capturas y acciones de sesión.
- Notificaciones (servidor opcional), portapapeles en memoria y vista de ventanas.
- Ajustes con barra lateral: apariencia, escritorio, dock, barra,
  notificaciones, accesibilidad, privacidad y estado de integración.
- Widgets de escritorio: reloj analógico, uso de CPU/memoria y calendario.
- Atajos de teclado mediante `qs ipc call novashell toggle <panel>`.

### Apariencia
- Materiales Cristal, Esmerilado y Sólido; claro/oscuro; alto contraste,
  reducir transparencia y reducir movimiento.
- Vidrio solo en la capa de navegación; controles y contenido con rellenos
  planos (pautas Liquid Glass de Apple).
- Blur de fondo solo si el compositor anuncia `ext-background-effect-v1`.
- Biblioteca de iconos MacTahoe (GPL-3.0, 16 602 nombres) y carpetas propias.
- Perfiles reversibles de Dolphin y KWin: `novactl desktop-profile`.

### Plataforma
- Daemon `nova-platform` (C++/Qt6) con contrato IPC v1 versionado: socket
  Unix `0600`, verificación de UID, límites de tamaño y clientes.
- Instalación sin root en `~/.local`, servicios systemd de usuario.
- CI: compilación estricta, ASan/UBSan, Quickshell real, renderizado Qt,
  reglas de arquitectura y bloqueo de atribución de IA.

### Corregido durante el ciclo
- Uso de memoria liberada al cerrar el daemon con clientes conectados.
- Las preferencias guardadas nunca se aplicaban (`Quickshell.env` devuelve `null`).
- El catálogo de aplicaciones no se cargaba al conectar (dock vacío).
- Preferencia de blur y detección del compositor se pisaban entre sí.

### Retirado
- Capa de iconos GoldenGate v3: su autor la describe como una recopilación
  de iconos de terceros, por lo que su licencia no cubría ese arte.

[Sin publicar]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/compare/v0.1.0...main
[0.1.0]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/releases/tag/v0.1.0
