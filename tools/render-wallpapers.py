#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Genera los fondos de NovaShell (claro y oscuro) de forma reproducible.

Los usan el splash, el tema SDDM y la pantalla de bloqueo, para que el inicio
de sesión, la carga y el escritorio compartan identidad. Los colores parten de
los tokens previewTop/previewBottom y del acento de Theme.qml.

Uso: render-wallpapers.py [--size 3840x2160] [--out assets/wallpapers]
Requiere numpy y Pillow (solo para regenerar; el resultado está versionado).
"""
import argparse
import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent

# (arriba, abajo, [(x, y, radio, color, intensidad)]) en coordenadas 0..1.
PALETTES = {
    "light": ("#dce9fb", "#e6d9ec", [
        (0.82, 0.30, 0.42, "#9cc2ff", 0.55),
        (0.12, 0.85, 0.40, "#f0b8d8", 0.45),
        (0.50, 1.05, 0.38, "#b6a8f5", 0.40),
    ]),
    "dark": ("#16243b", "#2a1f38", [
        (0.82, 0.28, 0.45, "#3478f6", 0.42),
        (0.10, 0.88, 0.42, "#8a3f7a", 0.40),
        (0.52, 1.08, 0.40, "#5b48c9", 0.38),
    ]),
}


def rgb(value):
    value = value.lstrip("#")
    return np.array([int(value[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def render(name, width, height):
    top, bottom, orbs = PALETTES[name]
    y, x = np.mgrid[0:height, 0:width].astype(np.float32)
    v, u = y / height, x / width
    image = rgb(top) * (1 - v[..., None]) + rgb(bottom) * v[..., None]
    aspect = width / height
    for ox, oy, radius, color, strength in orbs:
        distance = np.sqrt(((u - ox) * aspect) ** 2 + (v - oy) ** 2) / (radius * aspect)
        weight = (strength * np.exp(-3.2 * distance ** 2))[..., None]
        image = image * (1 - weight) + rgb(color) * weight
    # Ruido determinista de ±1 nivel: evita bandas en degradados de 8 bits.
    noise = np.random.default_rng(27).uniform(-1, 1, image.shape[:2])[..., None]
    return Image.fromarray(np.clip(image + noise, 0, 255).astype(np.uint8))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", default="3840x2160")
    parser.add_argument("--out", default=str(ROOT / "assets/wallpapers"))
    args = parser.parse_args()
    width, height = (int(part) for part in args.size.split("x"))
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in PALETTES:
        path = out / f"nova-{name}.jpg"
        render(name, width, height).save(path, quality=88, optimize=True, progressive=True)
        print(f"{path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}: {path.stat().st_size // 1024} KiB")


if __name__ == "__main__":
    main()
