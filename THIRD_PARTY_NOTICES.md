# Third-party notices

## Corner geometry and vector paths

Portions of `shell/nova/theme/CornerGeometry.mjs` and the symbol paths in
`shell/nova/icons/IconCatalog.mjs` use GPLv3.

- License: GNU General Public License version 3; full text in `LICENSE`.
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

`assets/icon-sources/file-manager.svg` preserves the same library's file-manager
artwork and license. The exporter retains the full vector for normal sizes and
generates a 16 px variant without subpixel Gaussian filters for Qt SVG. Paths,
colors and identity are preserved; the existing bundled authorship applies.

