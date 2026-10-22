# Criterios de optimización

La base se contrasta con las API estables utilizadas por el proyecto:

| Documentación oficial | Aplicación en NovaShell | Comprobación |
| :--- | :--- | :--- |
| [Qt 6.12: rendimiento de QML](https://doc.qt.io/qt-6.12/qtquick-performance.html) | Evitar trabajo repetido en bindings, cargar paneles bajo demanda y detener temporizadores sin trabajo | Pruebas de políticas, inspección de Loader y regresión del cliente IPC |
| [Qt 6.12: Image](https://doc.qt.io/qt-6.12/qml-qtquick-image.html) | Archivos de iconos asíncronos, proveedores de tema en el hilo GUI, caché de Qt y rasterización acotada por tamaño y escala | Renderizado Qt y resolución de iconos |
| [Qt 6.12: TextField](https://doc.qt.io/qt-6.12/qml-qtquick-controls-textfield.html) | Fondo, texto, selección y foco controlados por Theme | Cambio claro/oscuro, teclado y búsqueda sin resultados |
| [Quickshell 0.3.2: Socket](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Socket/) | Conexión asíncrona, flush tras escritura y renovación de socket al cambiar la ruta | Motor real con socket Unix, cancelación y caducidad |
| [Qt 6.12: SmoothedAnimation](https://doc.qt.io/qt-6.12/qml-qtquick-smoothedanimation.html) | Magnificación y ocultación del dock con continuidad al cambiar el destino | Sintaxis y aceptación visual pendiente en KWin |
| [Qt 6.12: Loader](https://doc.qt.io/qt-6.12/qml-qtquick-loader.html) | Paneles con foco explícito y descarga al terminar el cierre | Ciclo de apertura/cierre y movimiento reducido con Qt real |

## Movimiento y materiales

Los paneles usan opacidad y escala en el scene graph. Al cerrar dejan de aceptar
entrada y su contenido se descarga al terminar la transición; sin movimiento,
el cambio es inmediato. No usan capturas por fotograma ni capas de renderizado
adicionales. La barra y los accesos del dock usan botones planos con estado de
hover, pulsación y foco, evitando marcos permanentes alrededor de cada símbolo.

La transparencia y el desenfoque son controles distintos. El blur continúa
condicionado al protocolo anunciado por el compositor; reducir transparencia
o activar alto contraste mantiene superficies opacas. No se acredita una
reproducción exacta de materiales de otro sistema sin aceptación visual real.

## Lanzador y búsqueda

- **Índice por catálogo:** los nombres, nombres genéricos, palabras clave e
  ID se normalizan (sin acentos ni mayúsculas) una vez por catálogo
  (`DesktopPolicy.searchIndex`); cada pulsación solo puntúa y ordena.
- **Relevancia:** inicio del nombre > inicio de palabra > iniciales («lc» →
  LibreOffice Calc) > dentro del nombre > nombre genérico, palabras clave o
  ID. Intro abre el primero; el resaltado lo marca mientras se escribe.
- **Teclado:** ↓ pasa a la rejilla, ↑ vuelve, escribir con la rejilla enfocada
  sigue buscando, Esc borra la búsqueda y con el campo vacío cierra.
- **Celdas ligeras:** un solo menú contextual para toda la rejilla (antes un
  `Menu` por celda), reutilización de delegados y el icono genérico solo
  cuando no hay icono real o falla, nunca mientras carga.
- **Movimiento:** el resaltado se desliza `Theme.motion.fast` entre celdas;
  no hay animaciones por pulsación (el contenido cambia al instante, como
  Spotlight) y con menos movimiento el desplazamiento es inmediato.

Medida local (Qt 6.12, renderizador por software, 840×640, 300 aplicaciones
con iconos SVG reales, 75 pulsaciones): **37 ms → 18 ms por pulsación**
(filtrar, actualizar celdas y pintar). `node --test` comprueba la relevancia
y que 2.000 aplicaciones se filtran en menos de 200 ms para seis consultas.

## Reposo

Medida en sway sin GPU durante 20 s con el escritorio en reposo:

| Proceso | Antes | Después |
| :--- | :--- | :--- |
| `qs` con widgets de escritorio | 1,25 % CPU | **0,10 % CPU** |
| `qs` sin widgets | 0,15 % CPU | — |
| `nova-platform` | 0 % CPU, 17,5 MiB | 0 % CPU, 17,5 MiB |

La diferencia venía de animar las barras de CPU/RAM en cada refresco de
10 s; ahora se actualizan en un solo fotograma y en pasos del 2 %, así que una
variación mínima de memoria no repinta el widget. La memoria residente de `qs`
(~270 MiB) en este entorno incluye el OpenGL por software (llvmpipe); debe
medirse con GPU en Plasma.

## Agrupación del dock

Los identificadores cortos se indexan una vez por evaluación del catálogo.
La agrupación pasa de buscar por todas las aplicaciones para cada ventana
`O(aplicaciones × ventanas)` a `O(aplicaciones + ventanas + fijados)` con
mapas y conjuntos. Los identificadores ambiguos conservan el fallback y no
se asignan a una aplicación equivocada.

Una comparación local con Node, 5.000 aplicaciones y 128 ventanas produjo una
mediana aproximada de 185 ms antes y 4 ms después en 15 repeticiones. Se
compararon también los resultados completos. Es una medida de esa función en
ese entorno; no acredita FPS, memoria ni consumo de una sesión Plasma.

## Comunicación

El cliente admite hasta 128 peticiones pendientes y hasta 50 lecturas en cola.
El plazo de 10 s empieza al solicitar la operación, aunque no haya conexión.
Los mensajes mayores de 64 KiB UTF-8 se rechazan antes de escribirlos. Las
respuestas con forma o versión incorrectas no consumen una petición válida.
Deshabilitar el cliente cierra el socket y cancela lo pendiente.

La caducidad no despierta sin peticiones; la reconexión no despierta sin ruta.
Estos límites se comprueban con Quickshell real, no con una implementación
alternativa de sus clases.

## Validación pendiente en equipo real

El catálogo usa `NovaProgressBar`: barra indeterminada mientras se desconoce
el total y progreso real por páginas cuando el daemon lo proporciona. No se
simula un porcentaje ni se anima cuando está oculto, deshabilitado o se reduce
el movimiento. Las métricas CPU/RAM siguen siendo medidores, no tareas.
Qt comprueba el paso indeterminado → determinado, la saturación del valor y
la detención al ocultar o reducir movimiento.

La comprobación de iconos incluye carpetas de documentos, descargas, imágenes,
música, vídeos, remotas, abiertas y personales en cuatro variantes y cinco
tamaños: 440 resoluciones y renderizados Qt. Resolver un nombre no certifica
que su dibujo corresponda a una versión específica de otro sistema.
El icono de Dolphin conserva su vector completo para tamaños normales; su
variante de 16 px omite filtros gaussianos de detalle subpíxel que provocaban
avisos de buffers en Qt SVG. Las pruebas de resolución fallan ante cualquier
aviso del renderizador, además de comprobar imágenes no vacías.

Medir con el QML Profiler y una sesión Plasma: coste de abrir paneles,
desplazamiento del lanzador, varias pantallas, escalado y efectos del compositor.
Los cambios de complejidad y las pruebas funcionales no sustituyen esas medidas.

## Contraste visual

Se revisaron las imágenes publicadas por Apple en la presentación de
[macOS 27](https://www.apple.com/in/os/macos/) y la
[guía de Finder para 27](https://support.apple.com/en-by/guide/mac-help/mchlp2605/27/mac/27),
además de las guías de
[progreso](https://developer.apple.com/design/human-interface-guidelines/progress-indicators),
[movimiento](https://developer.apple.com/design/human-interface-guidelines/motion) y
[materiales](https://developer.apple.com/design/human-interface-guidelines/materials).
Son imágenes del fabricante, no capturas obtenidas ejecutando ese sistema.

Se observan agrupaciones de controles redondeadas, separación de navegación
y contenido y una barra lateral diferenciada. La adaptación usa los tokens de
NovaShell y las APIs Qt/KDE; las imágenes no proporcionan medidas exactas ni
una especificación de rendimiento para Linux.

| Área | Comprobado | Falta validar o implementar |
| :--- | :--- | :--- |
| Progreso del shell | Valores reales, estados y movimiento reducido | Captura y rendimiento en Plasma |
| Paneles | Entrada/salida y descarga del contenido tras cerrar | Escalado, varias pantallas y frecuencia alta |
| Ventanas externas | Perfiles KWin con efectos mutuamente excluyentes | Aceptación con KWin y GPU reales |
| Dolphin | Paletas y tamaños de vista nativos | Estilo Qt Widgets y materiales de cabecera/barra lateral |
| Iconos/carpetas | Biblioteca offline y 13 roles de carpetas propios en cuatro apariencias | Migración y auditoría visual completas frente a 27 |

La biblioteca empaquetada conserva su revisión y licencia en el manifiesto;
su base es Tahoe, en su última revisión publicada comprobada el 22-10-2026.
La capa propia de carpetas (vidrio monocromo, sin tinte azul) inicia la adaptación visual a Golden Gate:
`assets/icon-appearance.json` registra explícitamente una migración parcial,
separada de la versión de la biblioteca base. Usa vectores sin filtros,
variantes ópticas de 16 px y símbolos distintos por función; las cuatro
apariencias no dependen de generar imágenes en tiempo de ejecución.
No se etiqueta la colección completa como un paquete oficial o verificado de 27.
Las barras de copia y los errores de operaciones de archivos pertenecen a
KIO/Plasma: un control QML del shell no modifica su estilo Qt Widgets.
