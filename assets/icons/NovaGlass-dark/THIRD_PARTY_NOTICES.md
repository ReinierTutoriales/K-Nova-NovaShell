# Third-party notices

## Corner geometry and vector paths

Portions of `shell/nova/theme/CornerGeometry.mjs` and the symbol paths in
`shell/nova/icons/IconCatalog.mjs` use GPLv3.

- License: GNU General Public License version 3; full text in `LICENSE`.
- Modified October 22, 2026: selected pure functions, a bounded SVG registry,
  semantic names and new application artwork for NovaShell.

The adapted portions are conservatively marked GPL-3.0-only. Original NovaShell
files remain GPL-3.0-or-later; a combined distribution must comply with GPLv3.
No SF Symbols, proprietary fonts, wallpaper or native compositor plugins
are bundled. Application artwork and its release notices are detailed below.

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

## GoldenGate application artwork

`assets/goldengate-library.tar.xz` contains the raster application layer from
Golden-Gate-app-icons-by-PVZL release v3. The release includes GPLv3 `COPYING`
and `AUTHORS`, retained in both installed layers along with a modification notice.

- Source: https://github.com/PuzzlePieceee/Golden-Gate-app-icons-by-PVZL/releases/tag/v3
- Pinned release archive digests: `assets/goldengate-library.json`.
- Modified: PNGs bounded to 256 px, duplicate artwork addressed by content hash,
  relative aliases, corrected application identities and native theme indexes.
- Community artwork; not an official Apple system asset distribution. The base
  vector library remains a fallback for names not covered by this layer.
- Rebuild: `tools/vendor-goldengate.py` with both pinned release archives and Qt
  6.12's PySide6-Essentials. No build tooling or download is needed at runtime.
