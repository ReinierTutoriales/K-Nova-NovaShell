# Lanzamientos

## Versiones

- `VERSION` contiene la versión de las fuentes (`X.Y.Z` o `X.Y.Z-dev`).
- SemVer. Mientras la versión sea `0.x`, una versión menor puede romper
  compatibilidad; los cambios incompatibles del IPC exigen además `version: 2`
  en el contrato.
- Las etiquetas son `vX.Y.Z`, sobre un commit de `main` con el CI en verde, y
  no se mueven ni se reescriben una vez publicadas.

## Pre-release o estable

Una versión se publica como **pre-release** hasta que se haya validado en una
sesión Plasma real con la versión mínima de `packaging/runtime.env`: blur de
KWin, GPU, consumo en reposo, puente KWin y servicios del sistema. Solo
entonces puede marcarse como estable.

## Pasos

1. En una rama `release/X.Y.Z`: fijar `VERSION`, completar `CHANGELOG.md`
   y actualizar `README.md` y `docs/HOJA-DE-RUTA.md` al estado comprobado.
2. Verificación completa (ver `AGENTS.md`) y CI en verde en el PR.
3. Fusionar en `main`, crear la etiqueta `vX.Y.Z` sobre el commit fusionado
   y publicar la release con las notas de `CHANGELOG.md`.
4. En `main`, pasar `VERSION` a la siguiente `X.Y.Z-dev`.

Todos los commits y etiquetas van a nombre de ReinierTutoriales, sin
atribución de asistentes.
