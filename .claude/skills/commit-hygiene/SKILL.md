---
name: commit-hygiene
description: "Verificación final, mensajes de commit y prohibición de atribución de IA. Use when finishing changes or preparing commits."
---

# Higiene de commits y atribución

## Antes de considerar el cambio listo

1. Ejecuta todos los comandos de verificación de AGENTS.md.
2. Confirma que `tools/check-sources.py` pasa (0 problemas).
3. Confirma que los tests relevantes pasan.
4. Inspecciona `git status` y el diff. No uses `git commit -a`.
5. Separa cambios funcionales, documentación e higiene en commits revisables.

## Reglas de atribución (obligatorias)

- Autor y committer siempre ReinierTutoriales.
- **Prohibido** cualquier `Co-Authored-By` de IA, emails de servicios de IA (anthropic, copilot, etc.), "Generated with", o similar.
- **Prohibido** crear o usar ramas con nombres de asistentes (`claude/...`, `cursor/...`, etc.).
- Los mensajes de commit son descriptivos y neutrales.

El workflow `.github/workflows/block-ai-coauthor.yml` rechaza PRs que violen esto.

## Mensajes de commit

Usa mensajes claros en español o inglés, enfocados en el qué y el porqué. No menciones herramientas de IA.
