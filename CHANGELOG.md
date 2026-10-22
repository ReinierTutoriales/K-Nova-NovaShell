# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/);
versiones según [SemVer](https://semver.org/lang/es/). Mientras la versión sea
`0.x`, cualquier versión menor puede romper compatibilidad.

## [Sin publicar]

### Añadido
- `novactl install` aplica el aspecto nativo de forma reversible: iconos
  NovaGlass, paleta NovaGlass clara u oscura según la actual, acento Liquid
  Glass neutro (retira el acento personalizado o del fondo), Dolphin,
  transiciones de KWin, splash y fondo de bloqueo. `--no-profile` lo omite;
  `uninstall` lo restaura.
- Perfil nativo: claves de iconos, acento y paleta (`--appearance
  auto|light|dark`, `--keep-look`) y efectos Blur, Maximize, Slide y Fading
  Popups (desactivados en `reduced`). Registro versión 3 con migración.
- 73 sinónimos de carpetas (Dolphin, KIO, biblioteca heredada) enlazados a los
  13 roles propios.

### Cambiado
- Carpetas NovaGlass en vidrio monocromo (perla y grafito) en las cuatro
  apariencias; sin tonos azules.
- Reinstalar reaplica el perfil activo: solo se bloquea si el usuario cambió
  una clave que el perfil gestiona.

## [0.3.0] — 2026-10-22 · pre-release

Liquid Glass sin acento de color en todo el sistema, intensidad del vidrio y
desenfoque ajustables, nuevo icono y buscador del lanzador, y menos consumo en
reposo. Probado con Quickshell 0.3.2 y Qt 6.12.0 reales; **pendiente de
validar en Plasma 6.8 y SDDM reales**, por eso sigue como pre-release.

### Añadido
- Nuevo icono del lanzador en la barra y el dock: lupa con destello
  (símbolo `launcher`), que abre el lanzador con el cursor en la búsqueda.
- Control **Vidrio** (de opaco a transparente) en Ajustes y en la bienvenida,
  con vista previa en vivo, y control **Desenfoque** (intensidad del Blur de
  KWin, 1–15) mediante las operaciones nuevas `blur.get` y `blur.set`.

### Cambiado
- Lanzador: búsqueda por relevancia (inicio del nombre, palabras,
  iniciales, nombre genérico y palabras clave), índice normalizado una vez
  por catálogo, resaltado del resultado que abre Intro, Esc que borra antes de
  cerrar y escritura directa desde la rejilla. Un solo menú contextual y
  delegados reutilizados: de 37 a 18 ms por pulsación con 300 aplicaciones.
- `applications.list` incluye `genericName` («Navegador web», «Terminal»).
- Widgets de escritorio en reposo: de 1,25 % a 0,10 % de CPU (sin animar las
  barras de uso en cada refresco y en pasos del 2 %).
- La intensidad del vidrio cubre un rango visible: con desenfoque, de 0,85 a
  0,10 de opacidad en Cristal (antes 0,78–0,58 y nunca por debajo de 0,38).
- Sin tonos azulados: fondos NovaShell monocromos (perla y grafito), tokens de
  vista previa neutros y paletas KDE NovaGlass con selección, foco y enlaces
  grises.
- La acción principal de vidrio se distingue del panel (vidrio claro sobre
  negro en oscuro, vidrio tinta en claro).
- **Acento Liquid Glass** en todo el sistema: sin azul. En claro, vidrio
  transparente claro; en oscuro, vidrio negro translúcido (la superficie
  oscura pasa de gris a negro). Indicadores, día de hoy, interruptores y
  progreso usan la tinta del texto; la acción principal es vidrio denso. El
  material predeterminado pasa a Cristal (`liquid`). Un acento de color sigue
  disponible (`glassAccent: false`), con relleno legible a 4,5:1 para
  cualquier color y foco derivado.
- Inicio de sesión de vidrio transparente (`LoginGlass`): campo, botón de
  entrar, avatares, menú de sesiones y botones del pie; velo claro/oscuro
  sobre el fondo, arco giratorio mientras se verifica, entrada suave y
  fundido al entrar. `theme.conf`: `accent` vacío por defecto (Liquid Glass).
- Marca monocroma (tinta clara u oscura según el esquema) en splash y
  bienvenida.

## [0.2.0] — 2026-10-22 · pre-release

Pantallas de sesión con la identidad de NovaShell, bienvenida de primer uso e
instalación verificada de extremo a extremo. Probado con Quickshell 0.3.2 y
Qt 6.12.0 reales y con la API de SDDM 0.21 simulada; **pendiente de validar
en Plasma 6.8 y SDDM reales**, por eso sigue como pre-release.

### Añadido
- Tema SDDM (Qt 6) de inicio de sesión: fondo desenfocado, fecha y hora,
  avatares, contraseña en cápsula, Bloq Mayús, fila de usuarios con teclado
  (Tab y flechas; Esc borra la contraseña), sesión, teclado y energía.
  `novactl login-theme` lo prueba sin root; copiarlo al sistema es un script
  aparte (`packaging/sddm/install-theme.sh`) que se ejecuta con `sudo`.
  `novactl doctor` detecta el gestor de sesión.
- Splash de inicio de sesión (paquete look-and-feel por usuario, solo splash)
  con progreso determinado por las etapas de `ksplashqml`.
- Fondo NovaShell claro/oscuro como paquete de Plasma, reproducible con
  `tools/render-wallpapers.py`, y marca propia.
- `desktop-profile` activa también el splash y el fondo de la pantalla de
  bloqueo, de forma reversible; migra los registros de 0.1.0.
- Bienvenida de primer uso (Apple HIG, *Onboarding*): breve, omitible y con
  cambios en vivo; se reabre desde Ajustes o `toggle welcome`.
- Estilo de botón principal (`prominent`) con relleno de acento accesible
  (4,8:1) y símbolos `restart`, `sleep` y `forward`.
- Guía de instalación paso a paso (`docs/INSTALACION.md`) y prueba de
  instalación de extremo a extremo en el CI (`tests/install_smoke.py`).

### Cambiado
- `novactl install` toma la lista de archivos instalados de CMake
  (`install_manifest.txt`) y compila sin las pruebas.
- `novactl uninstall` borra en lote (de minutos a segundos con la biblioteca
  de iconos) y elimina las carpetas que quedan vacías sin salir del prefijo.
- Medidas de las pantallas de sesión en `Theme` (sin literales de diseño).

### Corregido
- `novactl uninstall --purge` no borraba los ajustes del daemon
  (`~/.config/novashell`).

### Limitaciones conocidas
- La interfaz de bloqueo sigue siendo la de Plasma: KWin no implementa
  `ext-session-lock-v1` y `kscreenlocker` la carga del paquete de shell. Solo
  se cambia su fondo ([detalles](https://github.com/ReinierTutoriales/K-Nova-NovaShell/blob/v0.2.0/docs/SESION.md#bloqueo)).
- Plasma Login Manager no admite temas; el tema de inicio de sesión requiere SDDM.

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

[Sin publicar]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/compare/v0.3.0...main
[0.3.0]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/releases/tag/v0.3.0
[0.2.0]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/releases/tag/v0.2.0
[0.1.0]: https://github.com/ReinierTutoriales/K-Nova-NovaShell/releases/tag/v0.1.0
