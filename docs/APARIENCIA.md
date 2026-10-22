# Apariencia de NovaShell

## Componentes

| Ruta | Responsabilidad |
| :--- | :--- |
| `shell/nova/theme/Theme.qml` | Entradas de sesión y tokens resueltos |
| `AppearancePolicy.mjs` | Valores permitidos, rangos y opacidad de recuperación |
| `IconTokens.mjs` | Paletas compartidas entre QML y exportador |
| `CornerGeometry.mjs` | Geometría pura de esquinas superelípticas |
| `shell/nova/icons/IconCatalog.mjs` | Identidades semánticas y SVG con caché LRU de 256 entradas |
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
| `NOVA_BACKGROUND_BLUR` | `1` para solicitar blur al compositor |
| `NOVA_APPEARANCE_PREVIEW` | `1` para abrir la galería |

Ejemplo de desarrollo: `NOVA_APPEARANCE=dark NOVA_ICON_MODE=clear ./tools/novactl dev`.
Las variables deben llegar al proceso Quickshell; exportarlas al ejecutar
`novactl start` no las propaga automáticamente a las unidades systemd.
Para servicios utiliza un drop-in de usuario con `Environment=`.
Los cambios de la galería no se guardan todavía en disco.

## Transparencia y blur

`GlassSurface` dibuja un relleno y acabado, sin capturar lo que hay detrás.
La barra solicita `BackgroundEffect.blurRegion` solo al habilitar
`NOVA_BACKGROUND_BLUR=1`. Quickshell 0.3 requiere que el compositor anuncie
`ext-background-effect-v1`; no se usa un plugin ni el protocolo privado de otro
escritorio. Si no has confirmado ese soporte, deja el valor predeterminado:
la superficie mantiene opacidad mínima de 0.88. Reducir transparencia y alto
contraste fuerzan opacidad 1 y desactivan el blur.

Esta base no implementa refracción del escritorio ni reemplaza la decoración
de las ventanas. El blur real debe validarse en Plasma Wayland.

## Recursos y pruebas

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
