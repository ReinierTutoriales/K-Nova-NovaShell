---
name: qml-development
description: "Escribe y refactoriza componentes QML para NovaShell: ≤400 líneas, solo Theme para diseño, sin procesos de sistema. Use when creating or editing QML in shell/."
---

# Desarrollo de componentes QML

Sigue estas reglas en todo QML bajo `shell/`.

## Reglas duras

- Máximo 400 líneas por archivo. Si crece, divide en componentes con estado separado de la vista.
- Colores, radios, espacios, tipografía y duraciones **solo** desde el singleton `Theme`. Prohibidos literales de diseño.
- Prohibido `Process {}`, `execDetached()`, `Qt.openUrlExternally` con file: y cualquier ejecución de sistema. Datos del sistema solo vía `Platform` (IPC).
- Módulo correcto en `qmldir`: `module qs.nova.<nombre>`.
- Cabecera SPDX al inicio.

## Buenas prácticas de eficiencia

- Minimiza bindings y reevaluaciones. Usa `Connections` o señales explícitas cuando sea posible.
- Evita lógica pesada en QML; mueve cálculos complejos al daemon si es necesario.
- Componentes pequeños y reutilizables. Prefiere composición sobre herencia profunda.
- Respeta `Theme.reduceMotion` para animaciones.
- No accedas a archivos del sistema ni a DBus directamente desde QML.

## Flujo de trabajo

1. Diseña el componente para que sea ≤400 líneas desde el inicio.
2. Importa y usa `Theme` para todo lo visual.
3. Comunícate con el sistema exclusivamente a través de `Platform`.
4. Ejecuta `python3 tools/check-sources.py` y verifica que pasa.
5. Prueba en sesión Wayland si es UI visible.

Consulta `docs/ARQUITECTURA.md` para la estructura de directorios.
