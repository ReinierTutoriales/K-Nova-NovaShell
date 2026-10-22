#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Genera los fondos de NovaShell (claro y oscuro) de forma reproducible.

Los usan el splash, el tema SDDM y la pantalla de bloqueo, para que el inicio
de sesión, la carga y el escritorio compartan identidad. Los colores parten de
los tokens previewTop/previewBottom de Theme.qml: monocromos, sin azules.

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
    # Monocromo (Liquid Glass): perla en claro, grafito en oscuro; sin tintes.
    # Volúmenes de luz suaves con contraste suficiente para que el vidrio
    # translúcido se note encima.
    "light": ("#f4f4f6", "#dddce2", [
        (0.80, 0.24, 0.40, "#ffffff", 0.90),
        (0.12, 0.88, 0.42, "#bdbcc4", 0.70),
        (0.55, 1.08, 0.40, "#cfced5", 0.60),
        (0.30, 0.18, 0.26, "#e2e1e7", 0.45),
    ]),
    "dark": ("#16161a", "#08080a", [
        (0.80, 0.24, 0.42, "#5a5a62", 0.65),
        (0.12, 0.88, 0.40, "#34343a", 0.60),
        (0.55, 1.08, 0.40, "#44444b", 0.55),
        (0.30, 0.18, 0.24, "#2a2a30", 0.45),
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
