# Apariencia de NovaShell

## Componentes

| Ruta | Responsabilidad |
| :--- | :--- |
| `shell/nova/theme/Theme.qml` | Entradas de sesión y tokens resueltos |
| `AppearancePolicy.mjs` | Valores permitidos, rangos y opacidad de recuperación |
| `IconTokens.mjs` | Paletas compartidas entre QML y exportador |
| `CornerGeometry.mjs` | Geometría pura de esquinas superelípticas |
| `shell/nova/icons/IconCatalog.mjs` | Identidades semánticas y SVG con caché LRU de 256 entradas |
| `shell/nova/icons/FolderCatalog.mjs` | 13 roles de carpetas, cuatro apariencias y variantes ópticas estáticas |
| `Icon.qml` | Símbolos monocromos; color y escala desde Theme |
| `AppIcon.qml` | Arte vectorial de NovaShell; cuatro apariencias |
| `SystemAppIcon.qml` | Iconos de otras aplicaciones con carga síncrona y fallback |
| `shell/nova/controls` | Superficies, botones y foco de teclado |
| `shell/nova/preview` | Galería descargada al cerrar la ventana |
| `assets/icons/NovaGlass*` | Cuatro temas freedesktop preconstruidos |

Los SVG se componen de placa, acabado especular, borde y símbolo.
No contienen scripts, texto dependiente de fuentes, imágenes externas ni bitmaps.
La geometría continua del icono no implica que las ventanas de otras aplicaciones
adquieran esas esquinas. El renderizador de la superficie usa radios nativos de Qt.

## Preferencias

`Theme` valida las opciones antes de derivar tokens. Los valores desconocidos
vuelven al modo predeterminado; los números fuera de rango se acotan.
El modo automático sigue el esquema y la tipografía de Qt.

| Variable al iniciar Quickshell | Valores |
| :--- | :--- |
| `NOVA_APPEARANCE` | `auto`, `light`, `dark` |
| `NOVA_MATERIAL` | `liquid`, `frosted`, `solid` |
| `NOVA_ICON_MODE` | `default`, `dark`, `clear`, `tinted` |
| `NOVA_REDUCE_MOTION` | `1` para desactivar animaciones |
| `NOVA_REDUCE_TRANSPARENCY` | `1` para superficies opacas |
| `NOVA_HIGH_CONTRAST` | `1` para opacidad y bordes contrastados |
| `NOVA_BACKGROUND_BLUR` | `0` desactiva la preferencia de blur (por defecto activa) |
| `NOVA_COMPOSITOR_BLUR` | `1`/`0` fuerza el soporte detectado del compositor (diagnóstico) |
| `NOVA_APPEARANCE_PREVIEW` | `1` para abrir la galería |

Ejemplo de desarrollo: `NOVA_APPEARANCE=dark NOVA_ICON_MODE=clear ./tools/novactl dev`.
Las variables deben llegar al proceso Quickshell; exportarlas al ejecutar
`novactl start` no las propaga automáticamente a las unidades systemd.
Para servicios utiliza un drop-in de usuario con `Environment=`.
Los cambios de la galería no se guardan todavía en disco.

## Acento Liquid Glass

NovaShell no usa un acento de color por defecto. `Theme.glassAccent` (activo)
deriva todo del esquema:

| Token | Claro | Oscuro |
| :--- | :--- | :--- |
| Superficie de vidrio | blanca translúcida | negra translúcida (`#0e0f12`) |
| Indicadores (`color.accent`) | tinta oscura `#17191e` | tinta clara `#f5f6fa` |
| Acción principal (`accentFill`) | vidrio claro denso | vidrio negro denso |
| Foco | negro al 60 % | blanco al 75 % |
| Selección | negro al 8 % | blanco al 14 % |

Con `glassAccent: false` y `accent` (`#rrggbb`) vuelve un acento de color: el
relleno principal se oscurece lo justo para que el texto blanco cumpla 4,5:1
(`AppearancePolicy.readableFill`) y el foco se deriva del acento. El material
predeterminado es Cristal (`liquid`).

## Intensidad del vidrio y desenfoque

Ajustes → Apariencia (y la bienvenida) tienen dos controles:

- **Vidrio** (de *Opaco* a *Transparente*, preferencia `transparency`): se ve
  en vivo al arrastrar y se guarda al soltar. Rangos de opacidad de la
  superficie (`AppearancePolicy.surfaceAlpha`):

  | Material | Con desenfoque del compositor | Sin desenfoque |
  | :--- | :--- | :--- |
  | Cristal (`liquid`) | 0,85 → 0,10 | 0,95 → 0,55 |
  | Esmerilado (`frosted`) | 0,92 → 0,32 | 0,97 → 0,70 |
  | Sólido | 1 | 1 |

  Sin desenfoque se conserva un mínimo legible porque el fondo se ve nítido.
  Reducir transparencia y alto contraste fuerzan opacidad 1.
- **Desenfoque** (1–15): la intensidad del efecto Blur de KWin
  (`[Effect-blur] BlurStrength`), el que aplica a NovaShell vía
  `ext-background-effect-v1`. Se cambia con `blur.set` del daemon
  (`kwriteconfig6` + recarga del efecto por D-Bus) y solo aparece si
  `kwriteconfig6` está instalado.

## Transparencia y blur

`GlassSurface` dibuja un relleno y acabado, sin capturar lo que hay detrás.
El blur se decide solo (`CompositorBlur`): al conectar, el shell pide
`compositor.capabilities` al daemon y activa `BackgroundEffect.blurRegion`
únicamente si el compositor anuncia `ext-background-effect-v1`, el protocolo
que usa Quickshell 0.3. No se usa un plugin ni el protocolo privado de otro
escritorio. Con blur la superficie baja hasta opacidad 0.38 (vidrio); sin él
mantiene un mínimo de 0.88 para que el texto siga legible.
El blur exige la preferencia del usuario (Ajustes, activa por defecto) **y**
el soporte del compositor; `NOVA_COMPOSITOR_BLUR=1/0` fuerza la detección. Reducir transparencia
y alto contraste fuerzan opacidad 1 y desactivan el blur.

`GlassSurface` añade brillo especular superior y borde de luz interior
(intensos en Cristal, sutiles en Esmerilado, nulos en Sólido u opaco). Son
nodos estáticos: no hay shaders por frame ni capturas del escritorio.

Esta base no implementa refracción del escritorio ni reemplaza la decoración
de las ventanas. El blur real debe validarse en Plasma Wayland.

## Pautas de Apple aplicadas

Referencia: Apple Human Interface Guidelines (Motion, Progress indicators,
Materials) y la sesión WWDC25 «Meet Liquid Glass». macOS 27 (Golden Gate)
ajustó la transparencia de Liquid Glass para que botones y etiquetas se lean
mejor; NovaShell prioriza la legibilidad por la misma razón.

| Pauta | Cómo se aplica |
| :--- | :--- |
| Vidrio solo en la capa de navegación | `GlassSurface` en barra, dock, paneles, widgets y avisos flotantes. |
| No apilar vidrio sobre vidrio | Controles sobre vidrio usan `ControlFill` (relleno de estado) y el contenido `ContentCard`. |
| Tinte solo en elementos primarios | Acento Liquid Glass sin color: selección, progreso, interruptores activos y el día de hoy usan la tinta del texto; la acción principal es vidrio denso (claro en claro, negro en oscuro). |
| Movimiento breve, con propósito e interrumpible | Paneles: abrir 200 ms (OutCubic), cerrar 120 ms (InCubic); las `Behavior` se interrumpen solas. |
| Evitar animar interacciones frecuentes | Ampliación del dock desactivada por defecto (como en macOS); hover solo cambia el relleno. |
| Movimiento opcional | «Reducir movimiento» lleva las duraciones a 0 y quita barridos y ampliación. |
| Progreso determinado cuando se conoce el total | El catálogo pasa de indeterminado a determinado en la misma barra. |
| Ritmo honesto, sin saltos ni parones | El relleno avanza suavizado; la barra no aparece en operaciones de menos de 250 ms. |
| Etiquetas concretas | «Leyendo aplicaciones instaladas: 24 de 230», no «Cargando…». |

## Recursos y pruebas

El objetivo visual es macOS 27 Golden Gate. La migración actual es parcial y
se registra en `assets/icon-appearance.json`: carpetas propias, sin extraer
recursos del sistema de Apple; la biblioteca base conserva su versión real.
Los símbolos de carpeta a 16 px representan la función (documentos, música,
descargas…) y las vistas grandes usan carpetas con distintivos. Seleccionar
NovaGlass, NovaGlass-dark, NovaGlass-clear o NovaGlass-tinted en los ajustes de
iconos de KDE extiende esa capa a Dolphin; cambiar el modo del shell no cambia
automáticamente la preferencia global de KDE.

La prueba Qt exporta `build/desktop-folder-icons.png` con los iconos obtenidos
del tema real en dos tamaños. Es una captura de renderizado Qt, no de macOS
ni una sesión completa de Dolphin. Faltan la auditoría de todas las apps y
la aceptación en una sesión Plasma real.

La resolución de los iconos sigue la escala de pantalla, con tope 256 px.
Los iconos del proveedor KDE se cargan en el hilo de interfaz: no convertir
`SystemAppIcon` a carga asíncrona sin validar la seguridad del motor de iconos.
Ningún icono necesita MultiEffect, un FBO por delegado ni una animación permanente.

Regenerar los temas: `node tools/export-icons.mjs assets/icons`.
Comparar salida reproducible: exportar a `build/icon-check` y ejecutar
`diff -r assets/icons build/icon-check`.
Las variantes heredan la biblioteca completa de sistema y Breeze/hicolor;
no cambian asociaciones de aplicaciones ni el tema seleccionado en Plasma.

## Biblioteca completa de sistema

Se incluyen 16.602 nombres únicos (incluidos alias) y 27.508 entradas SVG en
el tema base, repartidas entre 11 contextos. El paquete local ocupa 4,55 MB;
comparte recursos idénticos mediante enlaces relativos. Incluye cursores Xcursor
y variantes de sistema base, clara y oscura. Todos los temas se instalan juntos
porque comparten archivos. `assets/icon-library.json` registra revisión,
SHA-256, recuentos y categorías; CMake verifica el archivo antes de extraerlo.
No se descarga nada al compilar, instalar o mostrar un icono.

`SystemAppIcon { iconName: "org.kde.dolphin" }` resuelve el nombre mediante
Quickshell y muestra un icono genérico si falta. La configuración raíz selecciona
`NovaGlass` solo para el proceso. Para la variante oscura completa, inicia con
`QS_ICON_THEME=NovaGlass-dark`; para usarla en todo Plasma, selecciona el tema
en Preferencias del sistema > Colores y temas > Iconos. Los modos clear/tinted
solo modifican los iconos propios; no convierten toda la biblioteca de sistema.

Es iconografía redistribuible de estilo macOS para Linux, no una extracción de
los recursos oficiales de macOS 27. La cobertura no garantiza un icono específico
para todas las aplicaciones existentes. Los créditos y licencias se conservan
en los archivos legales. Para regenerar el paquete usa un checkout limpio de la
revisión fijada y `python3 tools/vendor-icon-library.py /ruta/al/checkout`.

`python3 tests/icon_library_test.py` comprueba el hash, todos los SVG, rutas,
enlaces, índices y cursores. Con `--qt` requiere PySide6 y prueba la resolución
nativa de aplicaciones y recursos estándar, en cuatro temas y cinco tamaños.

`node --test tests/appearance.test.mjs` valida rangos, esquinas, fallbacks,
colores, caché, exportación e identidades.
`python3 tests/appearance_smoke.py` requiere PySide6 y carga los componentes
portátiles reales, recorre 24 combinaciones, cambia accesibilidad, reabre la
galería y comprueba todos los SVG con QtSvg. Genera capturas en `build/`.
No incluye un sustituto de Quickshell ni simula validación Wayland.
