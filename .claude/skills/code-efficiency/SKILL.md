---
name: code-efficiency
description: "Optimiza rendimiento, uso de recursos y calidad de código en NovaShell. Use when reviewing or improving performance, memory, or code structure."
---

# Eficiencia y calidad de código

Objetivo: código rápido, ligero, mantenible y que pase todas las reglas.

## Principios

- Presupuesto de recursos desde el día 1. Evita inflar RSS o CPU en reposo.
- QML pequeños y con bindings mínimos. Prefiere señales explícitas sobre bindings profundos.
- Daemon: operaciones rápidas, límites estrictos (64 KiB, 32 clientes, etc.).
- Usa las herramientas existentes: `check-sources.py` impone límites y prohibiciones.
- No introduzcas dependencias innecesarias ni código muerto.

## Checklist de optimización

- ¿El QML está ≤400 líneas y usa solo Theme?
- ¿No hay procesos ni acceso directo al sistema desde la UI?
- ¿Las operaciones IPC son acotadas y documentadas?
- ¿Los tests pasan y el CI estaría verde?
- ¿Se ha medido o razonado el impacto en memoria/CPU?
- ¿El código es claro y evita duplicación?

## Verificación

Siempre ejecuta el bloque completo de AGENTS.md antes de considerar el cambio listo. Para cambios de UI, recuerda que la validación visual requiere Plasma Wayland real.

Consulta la hoja de ruta para presupuestos de recursos planificados.
