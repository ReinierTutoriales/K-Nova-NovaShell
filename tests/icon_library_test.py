# SPDX-License-Identifier: GPL-3.0-or-later
"""Validate the complete offline bundle and optionally Qt's actual theme lookup."""
import configparser
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import posixpath
import sys
import tarfile
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def validate():
    metadata = json.loads((ROOT / "assets/icon-library.json").read_text())
    archive = ROOT / "assets/icon-library.tar.xz"
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == metadata["archiveSha256"]
    with tarfile.open(archive) as bundle:
        members = bundle.getmembers()
        mapping = {item.name.rstrip("/"): item for item in members}
        assert len(mapping) == len(members), "Duplicate archive paths"
        for item in members:
            path = PurePosixPath(item.name)
            assert not path.is_absolute() and ".." not in path.parts
            assert path.parts[0] in metadata["themes"]
            assert item.isfile() or item.isdir() or item.issym()
            if item.issym():
                target = posixpath.normpath(posixpath.join(posixpath.dirname(item.name), item.linkname))
                assert not item.linkname.startswith("/") and target in mapping, item.name
            if item.isfile() and item.name.endswith(".svg"):
                ET.fromstring(bundle.extractfile(item).read())
        assert sum(item.isfile() for item in members) == metadata["physicalFiles"]
        assert sum(item.issym() for item in members) == metadata["aliases"]
        assert metadata["uniqueIconNames"] >= 16000
        with tempfile.TemporaryDirectory(prefix="nova-icon-test-") as temporary:
            # All paths and member types above are validated before extraction.
            bundle.extractall(temporary, **({"filter": "data"} if hasattr(tarfile, "data_filter") else {}))
            directory = Path(temporary)
            for item in members:
                path = directory / item.name
                if item.issym():
                    assert path.resolve(strict=True).is_relative_to(directory), item.name
            for theme in metadata["themes"]:
                base = directory / theme
                assert (base / "COPYING").is_file() and (base / "AUTHORS").is_file()
                index = configparser.ConfigParser(interpolation=None)
                index.read(base / "index.theme")
                for relative in index["Icon Theme"]["Directories"].split(","):
                    assert (base / relative).is_dir(), relative
                assert (base / "cursors/left_ptr").read_bytes().startswith(b"Xcur")
            if "--qt" in sys.argv:
                qt_lookup(directory)
    print(f"Icon library OK: {metadata['uniqueIconNames']} names; 3 themes; all SVG and aliases valid")


def qt_lookup(directory):
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    from PySide6.QtCore import Qt, QRect, QtMsgType, qInstallMessageHandler
    from PySide6.QtGui import QColor, QGuiApplication, QIcon, QImage, QPainter
    app = QGuiApplication.instance() or QGuiApplication([])
    warnings = []
    previous_handler = qInstallMessageHandler(lambda kind, context, message: warnings.append(message)
        if kind in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg) else None)
    QIcon.setThemeSearchPaths([str(ROOT / "assets/icons"), str(directory)])
    appearance = json.loads((ROOT / "assets/icon-appearance.json").read_text())
    samples = ["firefox", "org.kde.dolphin", "document-open", "audio-volume-high",
               "network-wireless", "computer", "text-plain", "user-trash", "nova-settings"] + appearance["folderRoles"]
    for theme in ["NovaGlass", "NovaGlass-dark", "NovaGlass-clear", "NovaGlass-tinted"]:
        QIcon.setThemeName(theme)
        for name in samples:
            assert QIcon.hasThemeIcon(name), (theme, name)
            for size in [16, 24, 64, 128, 256]:
                assert not QIcon.fromTheme(name).pixmap(size, size).isNull(), (theme, name, size)
    # Actual QIcon theme resolution, not a separately drawn approximation.
    roles = appearance["folderRoles"]
    gallery = QImage(140 + 82 * len(roles), 4 * 118, QImage.Format.Format_ARGB32_Premultiplied)
    painter = QPainter(gallery)
    for row, theme in enumerate(["NovaGlass", "NovaGlass-dark", "NovaGlass-clear", "NovaGlass-tinted"]):
        QIcon.setThemeName(theme)
        y = row * 118
        dark = theme.endswith("dark")
        painter.fillRect(QRect(0, y, gallery.width(), 118), QColor("#22252e" if dark else "#f4f5f8"))
        painter.setPen(QColor("#f5f6fa" if dark else "#17191e"))
        painter.drawText(QRect(8, y, 130, 118), Qt.AlignmentFlag.AlignVCenter, theme)
        for column, role in enumerate(roles):
            x = 140 + column * 82
            painter.drawPixmap(x + 9, y + 6, QIcon.fromTheme(role).pixmap(64, 64))
            painter.drawPixmap(x + 33, y + 73, QIcon.fromTheme(role).pixmap(16, 16))
            painter.drawText(QRect(x, y + 91, 82, 26), Qt.AlignmentFlag.AlignCenter | Qt.TextFlag.TextWordWrap,
                             role.replace("folder-", "").replace("inode-", ""))
    painter.end()
    (ROOT / "build").mkdir(exist_ok=True)
    assert gallery.save(str(ROOT / "build/desktop-folder-icons.png"))
    app.processEvents()
    qInstallMessageHandler(previous_handler)
    assert not warnings, "\n".join(warnings)
    print(f"Qt native theme lookup OK: {len(samples) * 4 * 5} renders, including folders and desktop IDs")


if __name__ == "__main__":
    validate()
