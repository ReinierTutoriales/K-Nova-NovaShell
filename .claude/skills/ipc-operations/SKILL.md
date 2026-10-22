---
name: ipc-operations
description: "Añade operaciones acotadas al daemon nova-platform y al contrato IPC v1. Use when extending platform capabilities or adding system operations."
---

# Añadir operaciones al contrato IPC

El contrato en `docs/CONTRATO-IPC-v1.md` es la fuente de verdad. El test `ipc_smoke` falla si no coincide con `platform.capabilities`.

## Pasos obligatorios

1. Diseña la operación como **acotada**: nunca acepta un comando arbitrario, una ruta de ejecutable ni argumentos que acaben en shell.
2. Implementa el manejador en el daemon (registra en `Router::makeDefault()` o módulo propio).
3. Añade la fila a la tabla de operaciones en `docs/CONTRATO-IPC-v1.md` (entre los marcadores `<!-- operaciones:inicio -->` y `<!-- operaciones:fin -->`).
4. Si es lectura idempotente, añádela a `readOperations` en `shell/nova/services/Platform.qml`.
5. Añade tests: unitario del manejador + caso en `tests/ipc_smoke.py` si toca el socket.
6. Verifica que `ctest` pasa y que `platform.capabilities` coincide.

## Reglas

- Escrituras fallan de inmediato si el daemon no está disponible; el cliente no las reintenta solo.
- Cambios incompatibles requieren `version: 2`, nunca reinterpretar campos de v1.
- Documenta e implementa en el **mismo** commit.

Consulta `docs/CONTRATO-IPC-v1.md` y `docs/DESARROLLO.md` para detalles.
