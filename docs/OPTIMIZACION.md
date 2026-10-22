# Criterios de optimización

La base se contrasta con las API estables utilizadas por el proyecto:

| Documentación oficial | Aplicación en NovaShell | Comprobación |
| :--- | :--- | :--- |
| [Qt 6.12: rendimiento de QML](https://doc.qt.io/qt-6.12/qtquick-performance.html) | Evitar trabajo repetido en bindings, cargar paneles bajo demanda y detener temporizadores sin trabajo | Pruebas de políticas, inspección de Loader y regresión del cliente IPC |
| [Qt 6.12: Image](https://doc.qt.io/qt-6.12/qml-qtquick-image.html) | Iconos asíncronos, caché de Qt y rasterización acotada por tamaño y escala | Renderizado Qt y resolución de iconos |
| [Qt 6.12: TextField](https://doc.qt.io/qt-6.12/qml-qtquick-controls-textfield.html) | Fondo, texto, selección y foco controlados por Theme | Cambio claro/oscuro, teclado y búsqueda sin resultados |
| [Quickshell 0.3.2: Socket](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/Socket/) | Conexión asíncrona, flush tras escritura y renovación de socket al cambiar la ruta | Motor real con socket Unix, cancelación y caducidad |

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

Medir con el QML Profiler y una sesión Plasma: coste de abrir paneles,
desplazamiento del lanzador, varias pantallas, escalado y efectos del compositor.
Los cambios de complejidad y las pruebas funcionales no sustituyen esas medidas.
