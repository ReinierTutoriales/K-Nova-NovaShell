#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Vendor the complete pinned desktop icon library as a deterministic archive.

Only build-time tooling: installation and runtime never fetch remote resources.
Original SVG bytes and license notices are retained. Duplicate payloads become
relative symlinks; unsafe/dangling source aliases are reported and omitted.
"""
import argparse
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import tarfile
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATEGORIES = ("actions", "animations", "apps", "categories", "devices", "emotes",
              "emblems", "mimes", "places", "preferences", "status")
BASE = "NovaGlass-System"
EXPECTED_SOURCE = "839848b9a8a38a92a6936e30c4abe35cc6f2546d"
SOURCE_URL = "https://github.com/vinceliuice/MacTahoe-icon-theme"


def merge_tree(source, destination):
    if not source.is_dir():
        return
    destination.mkdir(parents=True, exist_ok=True)
    for path in sorted(source.iterdir()):
        target = destination / path.name
        if path.is_symlink():
            if target.exists() or target.is_symlink():
                if target.is_dir() and not target.is_symlink():
                    raise ValueError("Alias would replace a directory: " + str(target))
                target.unlink()
            target.symlink_to(os.readlink(path))
        elif path.is_dir():
            merge_tree(path, target)
        else:
            if target.is_symlink():
                target.unlink()
            shutil.copyfile(path, target)


def entries(root):
    # Do not follow directory links (including @2x aliases).
    for current, directories, files in os.walk(root, followlinks=False):
        for name in sorted(directories + files):
            yield pathlib.Path(current) / name


def remove_invalid_links(root):
    invalid = []
    for path in list(entries(root)):
        if not path.is_symlink():
            continue
        try:
            resolved = path.resolve(strict=True)
            resolved.relative_to(root)
        except (ValueError, OSError, RuntimeError):
            invalid.append(str(path.relative_to(root)))
            path.unlink()
    return sorted(invalid)


def index_file(source, destination, name):
    text = source.read_text(encoding="utf-8")
    text = text.replace("Name=MacTahoe", "Name=" + name)
    text = text.replace("Comment=MacOSX Tahoe style icon theme for linux.",
                        "Comment=NovaShell complete desktop icon library")
    text = text.replace("Inherits=hicolor,breeze", "Inherits=breeze,hicolor")
    destination.write_text(text, encoding="utf-8")


def recolor(directory, before, after):
    for path in directory.rglob("*.svg"):
        if path.is_symlink():
            continue
        raw = path.read_text(encoding="utf-8")
        updated = raw.replace(before, after)
        if updated != raw:
            path.write_text(updated, encoding="utf-8")


def build_themes(source, staging):
    base = staging / BASE
    base.mkdir()
    for category in CATEGORIES:
        merge_tree(source / "src" / category, base / category)
    # The Budgie-specific panel is not part of Plasma's declared directories.
    budgie = base / "status" / "symbolic-budgie"
    if budgie.is_dir():
        shutil.rmtree(budgie)
    merge_tree(source / "links", base)
    index_file(source / "src" / "index.theme", base / "index.theme", BASE)

    for suffix in ("light", "dark"):
        variant = staging / (BASE + "-" + suffix)
        # Copy before deduplication: variant recoloring must never mutate base.
        shutil.copytree(base, variant, symlinks=True)
        index_file(source / "src" / "index.theme", variant / "index.theme", variant.name)
        if suffix == "light":
            for size in ("16", "22", "24", "32"):
                recolor(variant / "status" / size, "#f2f2f2", "#363636")
        else:
            for category, sizes in {
                "actions": ("16", "22", "24", "32", "symbolic"),
                "apps": ("16", "22", "32", "symbolic"),
                "categories": ("22", "symbolic"),
                "devices": ("16", "22", "24", "32", "symbolic"),
                "emblems": ("symbolic",),
                "mimes": ("symbolic",),
                "places": ("16", "22", "24", "symbolic"),
                "status": ("symbolic",)
            }.items():
                for size in sizes:
                    recolor(variant / category / size, "#363636", "#dedede")
            for name in ("user-trash", "user-trash-full"):
                original = variant / "places/scalable" / (name + "-dark.svg")
                target = variant / "places/scalable" / (name + ".svg")
                if original.is_file():
                    if target.is_symlink():
                        target.unlink()
                    shutil.copyfile(original, target)

    for theme in sorted(staging.iterdir()):
        for name in ("COPYING", "AUTHORS"):
            shutil.copyfile(source / name, theme / name)
        for category in CATEGORIES:
            (theme / (category + "@2x")).symlink_to(category, target_is_directory=True)

    # Cursor binaries are data, not executable code. Keep light and dark sets.
    for suffix, folder in (("", "dist"), ("-light", "dist"), ("-dark", "dist-dark")):
        merge_tree(source / "cursors" / folder / "cursors",
                   staging / (BASE + suffix) / "cursors")


def deduplicate(root):
    stored = {}
    saved = 0
    for path in sorted(entries(root)):
        if path.is_symlink() or not path.is_file() or path.name in ("index.theme", "COPYING", "AUTHORS"):
            continue
        raw = path.read_bytes()
        key = (path.suffix, hashlib.sha256(raw).hexdigest())
        if key in stored:
            canonical = stored[key]
            path.unlink()
            path.symlink_to(os.path.relpath(canonical, path.parent))
            saved += len(raw)
        else:
            stored[key] = path
    return saved


def archive_tree(root, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(target, "w:xz", format=tarfile.PAX_FORMAT, preset=9) as archive:
        for path in sorted(entries(root)):
            member = archive.gettarinfo(str(path), str(path.relative_to(root)))
            member.uid = member.gid = member.mtime = 0
            member.uname = member.gname = ""
            member.pax_headers = {}
            member.mode = 0o777 if member.issym() else 0o755 if member.isdir() else 0o644
            if member.isfile():
                with path.open("rb") as stream:
                    archive.addfile(member, stream)
            else:
                archive.addfile(member)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("--archive", type=pathlib.Path, default=ROOT / "assets/icon-library.tar.xz")
    parser.add_argument("--manifest", type=pathlib.Path, default=ROOT / "assets/icon-library.json")
    args = parser.parse_args()
    source = args.source.resolve()
    revision = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    dirty = subprocess.check_output(["git", "-C", str(source), "status", "--porcelain"], text=True)
    if revision != EXPECTED_SOURCE or dirty:
        raise ValueError("Use the clean pinned source revision " + EXPECTED_SOURCE)
    with tempfile.TemporaryDirectory(prefix="nova-icon-library-") as temporary:
        staging = pathlib.Path(temporary)
        build_themes(source, staging)
        invalid = remove_invalid_links(staging)
        saved = deduplicate(staging)
        if remove_invalid_links(staging):
            raise ValueError("Deduplication introduced broken aliases")
        base = staging / BASE
        counts = {}
        all_names = set()
        for category in CATEGORIES:
            icons = list((base / category).rglob("*.svg"))
            counts[category] = len(icons)
            all_names.update(path.stem for path in icons)
        physical = [p for p in entries(staging) if p.is_file() and not p.is_symlink()]
        aliases = [p for p in entries(staging) if p.is_symlink()]
        archive_tree(staging, args.archive)
        manifest = {
            "formatVersion": 1, "source": SOURCE_URL, "revision": revision,
            "license": "GPL-3.0", "themes": [BASE, BASE + "-light", BASE + "-dark"],
            "archiveSha256": hashlib.sha256(args.archive.read_bytes()).hexdigest(),
            "archiveBytes": args.archive.stat().st_size,
            "physicalFiles": len(physical), "aliases": len(aliases),
            "uniqueIconNames": len(all_names), "baseIconEntries": sum(counts.values()),
            "categories": counts, "duplicateBytesAvoided": saved,
            "omittedBrokenSourceAliases": invalid
        }
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({k: v for k, v in manifest.items()
                          if k != "omittedBrokenSourceAliases"}, indent=2))
        print("Omitted broken upstream aliases:", len(invalid))


if __name__ == "__main__":
    main()
