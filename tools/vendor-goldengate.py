# SPDX-License-Identifier: GPL-3.0-or-later
"""Build an offline GoldenGate v3 application layer; Qt needed only to rebuild.

Input archives are pinned by digest. No extraction or execution of their paths.
Keep the complete vector library as a separate fallback, not a replacement.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "light": ("GoldenGate.tar.gz", "04f9bd50bd1a5781e3177babc90b90b3d4ae94690e90b65c50c0f3d5dc20e1b8"),
    "dark": ("GoldenGateDark.tar.gz", "68241bbc375bde6684172cf6ca25e783fb82288f41d70886c2300afadbc57aa8"),
}
# Visual review found warning-text placeholders rather than application artwork.
EXCLUDED_ARTWORK = {"vim", "xterm"}
# Explicit identity corrections; do not map the Dolphin emulator to the file manager.
FIXES = {"code": "visualstudio", "code-oss": "visualstudio", "org.kde.konsole": "terminal",
         "konsole": "terminal", "xterm": "terminal", "org.codeberg.dnkl.foot": "terminal",
         "foot": "terminal", "footclient": "terminal", "org.kde.dolphin": "filee",
         "dolphin": "filee", "system-file-manager": "filee"}


def resolved(mapping, name):
    seen = set()
    for _ in range(64):
        if name in seen or name not in mapping:
            return None
        seen.add(name)
        member = mapping[name]
        if not member.issym():
            return name if member.isfile() else None
        if member.linkname.startswith("/"):
            raise ValueError("Absolute source alias")
        name = posixpath.normpath(posixpath.join(posixpath.dirname(name), member.linkname))
        if name.startswith("../"):
            raise ValueError("Escaping source alias")
    return None


def build_layer(source, variant, output):
    from PySide6.QtCore import QBuffer, QIODevice, Qt
    from PySide6.QtGui import QImage
    filename, digest = SOURCES[variant]
    archive = source / filename
    if hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
        raise ValueError("Source archive checksum mismatch: " + filename)
    theme = "NovaGlass-GoldenGate-" + variant
    payload = {}
    with tarfile.open(archive) as bundle:
        members = bundle.getmembers()
        mapping = {m.name.rstrip("/"): m for m in members}
        if len(mapping) != len(members) or len(members) > 50000:
            raise ValueError("Invalid source entry count")
        for member in members:
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts or not (member.isfile() or member.isdir() or member.issym()):
                raise ValueError("Unsafe source member")
        roots = {PurePosixPath(m.name).parts[0] for m in members}
        if len(roots) != 1:
            raise ValueError("Expected a single source root")
        root = roots.pop()
        for notice in ("COPYING", "AUTHORS"):
            payload[f"{theme}/{notice}"] = bundle.extractfile(root + "/" + notice).read()
        payload[f"{theme}/NOTICE"] = ("GoldenGate v3 community artwork layer.\n"
            "Original release notices are preserved. Not an official Apple asset package.\n"
            "Modified: bounded PNG size, relative aliases, native size index and identity corrections.\n").encode()
        originals, aliases, by_name, input_bytes = {}, {}, {}, 0
        # Only raster application artwork. Do not import the source's invalid
        # scalable-size declarations, blank files, scripts or cursors.
        prefix = root + "/apps/1024/"
        # Archive order avoids repeatedly inflating the gzip stream for random
        # seeks. Output order is sorted separately when writing the bundle.
        for member in members:
            name = member.name.rstrip("/")
            if not name.startswith(prefix) or not member.isfile() or not name.endswith(".png"):
                continue
            if Path(name).stem in EXCLUDED_ARTWORK:
                continue
            if member.size > 8 * 1024 * 1024:
                raise ValueError("Oversized source image")
            data = bundle.extractfile(member).read()
            if not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Invalid PNG")
            width, height = int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big")
            if not (1 <= width <= 2048 and 1 <= height <= 2048):
                raise ValueError("Unbounded PNG dimensions")
            image = QImage.fromData(data, "PNG")
            if image.isNull():
                raise ValueError("PNG decode failed")
            if max(width, height) > 256:
                image = image.scaled(256, 256, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            buffer = QBuffer()
            buffer.open(QIODevice.OpenModeFlag.WriteOnly)
            if not image.save(buffer, "PNG"):
                raise ValueError("PNG encode failed")
            encoded = bytes(buffer.data())
            original = "art-" + hashlib.sha256(encoded).hexdigest()
            originals[name] = original
            by_name[Path(name).stem] = original
            payload[f"{theme}/256x256/apps/{original}.png"] = encoded
            input_bytes += len(data)
        for name in sorted(mapping):
            if "/apps/" not in name:
                continue
            target = resolved(mapping, name)
            if target not in originals:
                continue
            alias = PurePosixPath(name).stem
            if not re.fullmatch(r"[A-Za-z0-9_.+-]{1,200}", alias):
                continue
            aliases[alias] = originals[target]
        for alias, target in FIXES.items():
            if target not in by_name:
                raise ValueError("Missing identity correction artwork")
            aliases[alias] = by_name[target]
        # Hash-addressed artwork keeps identity corrections independent: fixing
        # xterm must not also change Vim aliases that used the old xterm PNG.
        for alias, target in sorted(aliases.items()):
            path = f"{theme}/256x256/apps/{alias}.png"
            if alias != target:
                output[path] = target + ".png"
        payload[f"{theme}/index.theme"] = (f"[Icon Theme]\nName={theme}\n"
            "Comment=NovaShell GoldenGate application artwork\n"
            f"Inherits=NovaGlass-System-{variant},breeze,hicolor\n"
            "Directories=256x256/apps\n\n[256x256/apps]\nSize=256\n"
            "Type=Fixed\nContext=Applications\n").encode()
    output.update(payload)
    return {"theme": theme, "sourceFile": filename, "sourceSha256": digest,
            "artworks": len(originals), "iconNames": len(aliases),
            "sourcePngBytes": input_bytes,
            "optimizedPngBytes": sum(len(data) for path, data in payload.items() if path.endswith(".png"))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Directory containing both pinned v3 release archives")
    args = parser.parse_args()
    output = {}
    layers = [build_layer(args.source, variant, output) for variant in SOURCES]
    target = ROOT / "assets/goldengate-library.tar.xz"
    with tempfile.TemporaryDirectory(prefix="nova-goldengate-") as temporary:
        candidate = Path(temporary) / "library.tar.xz"
        with tarfile.open(candidate, "w:xz", format=tarfile.PAX_FORMAT, preset=9) as archive:
            for name, data in sorted(output.items()):
                member = tarfile.TarInfo(name)
                member.uid = member.gid = member.mtime = 0
                if isinstance(data, str):
                    member.type, member.linkname, member.mode = tarfile.SYMTYPE, data, 0o777
                    archive.addfile(member)
                else:
                    member.size, member.mode = len(data), 0o644
                    archive.addfile(member, io.BytesIO(data))
        target.write_bytes(candidate.read_bytes())
    manifest = {"formatVersion": 1, "release": "v3", "officialAppleAssets": False,
        "source": "https://github.com/PuzzlePieceee/Golden-Gate-app-icons-by-PVZL/releases/tag/v3",
        "license": "GPL-3.0", "maxRasterSize": 256,
        "archiveSha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "archiveBytes": target.stat().st_size, "layers": layers,
        "entries": len(output), "identityCorrections": FIXES,
        "excludedSourceArtwork": sorted(EXCLUDED_ARTWORK)}
    (ROOT / "assets/goldengate-library.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
