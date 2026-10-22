# Third-party notices

## Corner geometry and vector paths

Portions of `shell/nova/theme/CornerGeometry.mjs` and the original symbol
paths in `shell/nova/icons/IconCatalog.mjs` are adapted from NextKDE.

- Source: https://github.com/NextKde/NextKde
- Revision: `e877519b0ee810ac2d55689a86e8b49c83e33d86`
- Original files: `shell/desktop/modules/common/Squircle.mjs` and
  `shared/qml/controls/VectorIcon.qml`.
- License: GNU General Public License version 3; full text in `LICENSE`.
- The original files contain no individual copyright notices. Existing
  source comments describing the transferred functions are preserved where applicable.
- Modified October 22, 2026: selected pure functions, a bounded SVG registry,
  semantic names and new application artwork for NovaShell.

The adapted portions are conservatively marked GPL-3.0-only. Original NovaShell
files remain GPL-3.0-or-later; a combined distribution must comply with GPLv3.
No extracted Apple system assets, SF Symbols, proprietary fonts, wallpaper
or native compositor plugins are bundled.

## Complete system icon library

`assets/icon-library.tar.xz` contains the complete SVG sources, aliases and
Xcursor resources adapted from MacTahoe-icon-theme, distributed under GPLv3.

- Source: https://github.com/vinceliuice/MacTahoe-icon-theme
- Revision: `839848b9a8a38a92a6936e30c4abe35cc6f2546d`
- Original `COPYING`, `AUTHORS` and embedded artwork notices are preserved in
  each installed system theme. These include the upstream authors and credits.
- Modified October 22, 2026: renamed theme indexes, precomputed light/dark
  variants, internal relative aliases, deduplicated identical resources and
  deterministic packaging. Rebuild with `tools/vendor-icon-library.py`.

Application trademarks remain the property of their respective owners.

