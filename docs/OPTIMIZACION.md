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
Dolphin usa ahora el PNG acotado de GoldenGate v3, evitando los filtros
subpíxel del vector anterior que provocaban avisos de buffers en Qt SVG. Las pruebas de resolución fallan ante cualquier
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

La biblioteca base conserva su revisión y licencia en el manifiesto;
su base vectorial es Tahoe y funciona como respaldo. La capa de aplicaciones
se actualizó a GoldenGate v3, publicación comunitaria clara/oscura, con los
SHA-256 de ambos archivos de origen y del paquete generado.
La capa propia de carpetas inicia la adaptación visual a Golden Gate:
`assets/icon-appearance.json` registra explícitamente una migración parcial,
separada de la versión de la biblioteca base. Usa vectores sin filtros,
variantes ópticas de 16 px y símbolos distintos por función; las cuatro
apariencias no dependen de generar imágenes en tiempo de ejecución.
No se etiqueta la colección completa como un paquete oficial o verificado de 27.
Las barras de copia y los errores de operaciones de archivos pertenecen a
KIO/Plasma: un control QML del shell no modifica su estilo Qt Widgets.

## Capa de aplicaciones GoldenGate v3

La instalación incluye dos capas adicionales con 85 imágenes claras y 84
oscuras, y más de 1.500 nombres resueltos por variante. No sustituye la
cobertura vectorial de 16.602 nombres: las aplicaciones no cubiertas conservan
su respaldo. Las apariencias transparente/teñida de los iconos externos siguen
heredando el color normal; no se atribuye a v3 una variante que no distribuye.

Los PNG se reducen una sola vez al empaquetar, conservando la proporción y
limitando la dimensión mayor a 256 px. Se eliminan duplicados por hash; los
alias son relativos y apuntan directamente al recurso. La instalación no
descarga ni transforma imágenes. Se corrigieron las identidades de code,
xterm/terminales y Dolphin, distinguiendo el emulador del explorador. Se
excluyeron dos imágenes con texto de advertencia que sustituían a Vim; sus
alias conservan el respaldo vectorial válido.

El paquete comunitario no certifica que todos sus dibujos sean idénticos a
los de un sistema Apple 27. La comprobación Qt compara los píxeles resueltos
por herencia con el recurso nuevo para evitar que se siga mostrando el antiguo.
`build/desktop-goldengate-apps.png` muestra la resolución real clara/oscura.

Reconstrucción: `PYTHONPATH=/ruta/qt612 python3 tools/vendor-goldengate.py
/ruta/archivos-v3`. La herramienta solo lee los archivos con los hashes fijados;
Qt se necesita para reconstruir, no como dependencia Python de la instalación.

La comprobación programada de versiones consulta también la última publicación
estable de GoldenGate y marca una actualización para revisar; no instala
recursos nuevos sin comprobar hashes, identidades y renderizado.
