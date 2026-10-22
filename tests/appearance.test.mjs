// SPDX-License-Identifier: GPL-3.0-or-later
import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import * as Policy from "../shell/nova/theme/AppearancePolicy.mjs";
import * as Corners from "../shell/nova/theme/CornerGeometry.mjs";
import * as Icons from "../shell/nova/icons/IconCatalog.mjs";
import { folderNames, folderSvg } from "../shell/nova/icons/FolderCatalog.mjs";
import { styleFor, decode, exportTheme } from "../tools/export-icons.mjs";

test("invalid preferences cannot escape the supported appearance set", () => {
    for (const input of [null, undefined, {}, "unknown", "__proto__", "constructor"])
        assert.equal(Policy.choice(input, Policy.iconModes, "default"), "default");
    for (const input of [NaN, Infinity, -Infinity, "0.7", null])
        assert.equal(Policy.unit(input), 0.5);
    assert.equal(Policy.unit(-2), 0);
    assert.equal(Policy.unit(2), 1);
});

test("accessibility and compositor fallback preserve readable surface opacity", () => {
    for (const material of Policy.materials) {
        for (const alpha of [0, 0.5, 1, NaN]) {
            assert.equal(Policy.surfaceAlpha(material, alpha, true, true), 1);
            assert.ok(Policy.surfaceAlpha(material, alpha, false, false) >= 0.88);
            assert.ok(Policy.surfaceAlpha(material, alpha, false, true) <= 1);
        }
    }
    assert.ok(Policy.surfaceAlpha("liquid", 1, false, true)
        < Policy.surfaceAlpha("liquid", 0, false, true));
});

test("transferred corner geometry remains symmetric, bounded and circular at n=2", () => {
    assert.equal(Corners.normalizeExponent(NaN), 2);
    assert.equal(Corners.normalizeExponent(99), 8);
    assert.equal(Corners.clampCornerRadius(100, 10, 20), 10);
    assert.equal(Corners.squircleNorm(3, 4, 2), 5);
    for (const exponent of [2, 3, 4, 8]) {
        for (let y = 0; y <= 28; y++) {
            const x = Corners.halfExtentAt(y, 28, 28, 13, exponent);
            assert.ok(x >= 15 && x <= 28);
            assert.equal(x, Corners.halfExtentAt(-y, 28, 28, 13, exponent));
            if (y > 15)
                assert.ok(Math.abs(Corners.squircleDistance(x, y, 28, 28, 13, exponent)) < 1e-8);
        }
    }
    assert.doesNotMatch(Icons.tilePath(), /NaN|Infinity/);
});

test("all application icons generate four different valid local SVG sources", () => {
    assert.equal(Icons.applicationNames.length, 16);
    for (const name of Icons.applicationNames) {
        const variants = new Set();
        for (const mode of Policy.iconModes) {
            const xml = decode(Icons.applicationSource(name, mode, styleFor(name, mode === "dark")));
            assert.match(xml, /^<svg /);
            assert.match(xml, /viewBox="0 0 64 64"/);
            assert.doesNotMatch(xml, /NaN|undefined|https?:\/\/(?!www.w3.org)|<script|<image|<text/);
            variants.add(xml);
        }
        assert.equal(variants.size, 4, name);
    }
});

test("unknown and prototype-like icon IDs use the application fallback", () => {
    for (const name of ["missing", "__proto__", "constructor", "toString"])
        assert.equal(Icons.application(name), Icons.applications.application);
    assert.equal(Icons.symbolSource("__proto__", "#ffffff"),
        Icons.symbolSource("application", "#ffffff"));
});

test("SVG colors reject markup and translate Qt alpha byte order", () => {
    assert.throws(() => Icons.symbolSource("check", '"><script/>'));
    assert.throws(() => Icons.symbolSource("check", "#ffffff", 500));
    assert.match(decode(Icons.symbolSource("check", "#80ff0000")), /stroke="#ff000080"/);
});

test("icon cache remains bounded during continuous accent changes", () => {
    for (let i = 0; i < 600; i++)
        Icons.symbolSource("check", "#" + i.toString(16).padStart(6, "0"));
    assert.equal(Icons.cacheSize(), Icons.CACHE_LIMIT);
});

test("irrelevant palette changes reuse the same rendered icon source", () => {
    const initial = styleFor("files");
    const before = Icons.applicationSource("files", "default", initial);
    const changed = { ...initial, tint: "#ff0000", ink: "#000000",
        tile: "#333333", darkTile: "#111111", clearOpacity: 0.75 };
    const count = Icons.cacheSize();
    assert.equal(Icons.applicationSource("files", "default", changed), before);
    assert.equal(Icons.cacheSize(), count);
    const clear = Icons.applicationSource("files", "clear", initial);
    assert.equal(Icons.applicationSource("files", "clear",
        { ...initial, palette: ["#111111", "#222222"] }), clear);
});

test("exported freedesktop themes have complete assets and inheritance", () => {
    const temporary = mkdtempSync(join(tmpdir(), "nova-icons-"));
    try {
        exportTheme(temporary);
        const names = readdirSync(temporary);
        assert.equal(names.length, 4);
        for (const name of names) {
            assert.equal(readdirSync(join(temporary, name, "scalable/apps")).length, 16);
            assert.equal(readdirSync(join(temporary, name, "scalable/places")).length, folderNames.length);
            assert.equal(readdirSync(join(temporary, name, "16x16/places")).length, folderNames.length);
            const index = readFileSync(join(temporary, name, "index.theme"), "utf8");
            assert.match(index, /Inherits=.*hicolor/);
            assert.match(index, /Context=Applications/);
            if (name === "NovaGlass" || name === "NovaGlass-dark") assert.match(index, /Inherits=NovaGlass-GoldenGate-/);
        }
        assert.equal(readdirSync(join(temporary, "NovaGlass", "scalable/actions")).length,
            Icons.symbolNames.length);
    } finally {
        rmSync(temporary, { recursive: true });
    }
});

test("folder roles retain identity and have bounded optical size variants", () => {
    const manifest = JSON.parse(readFileSync(new URL("../assets/icon-appearance.json", import.meta.url), "utf8"));
    assert.deepEqual(manifest.folderRoles, folderNames);
    assert.equal(manifest.migrationStatus, "partial");
    assert.equal(manifest.officialSystemAssets, false);
    assert.throws(() => folderSvg("__proto__"));
    assert.throws(() => folderSvg("folder", "unknown"));
    for (const name of folderNames) {
        const normal = folderSvg(name);
        const small = folderSvg(name, "default", true);
        assert.notEqual(normal, small);
        assert.match(small, /stroke-width=/);
        const variants = new Set();
        for (const mode of ["default", "dark", "clear", "tinted"]) {
            const xml = folderSvg(name, mode);
            assert.doesNotMatch(xml, /<filter|<script|<image|NaN|undefined/);
            assert.ok(xml.length < 1600);
            variants.add(xml);
        }
        assert.equal(variants.size, 4);
    }
    assert.notEqual(folderSvg("folder-documents", "default", true), folderSvg("folder-music", "default", true));
    assert.notEqual(folderSvg("folder"), folderSvg("folder-open"));
    assert.notEqual(folderSvg("folder", "default", true), folderSvg("folder-open", "default", true));
    assert.match(folderSvg("folder", "clear"), /fill-opacity="0.45"/);
});
