// SPDX-License-Identifier: GPL-3.0-or-later
import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import vm from "node:vm";
import * as Policy from "../shell/nova/services/DesktopPolicy.mjs";

test("dock identities preserve pinned order and merge live windows", () => {
    const apps = [{id: "org.kde.dolphin.desktop", name: "Archivos", icon: "folder"}, {id: "firefox.desktop", name: "Firefox", icon: "firefox"}];
    const windows = [{id: "a", appId: "dolphin", title: "Uno"}, {id: "b", appId: "org.kde.dolphin", title: "Dos"}, {id: "c", appId: "firefox", title: "Web"}];
    const dock = Policy.dock(apps, ["firefox.desktop", "missing.desktop"], windows);
    assert.deepEqual(dock.map(item => item.id), ["firefox.desktop", "org.kde.dolphin.desktop"]);
    assert.equal(dock[1].windows.length, 2);
    assert.equal(dock[0].pinned, true);
    assert.equal(Policy.search(apps, "archí vos").length, 1);
    assert.equal(Policy.search(apps, "not-here").length, 0);
});
test("short desktop IDs resolve only when unambiguous", () => {
    const apps = [{id:"org.example.shared.desktop",name:"One"}, {id:"io.example.shared.desktop",name:"Two"},
        {id:"org.example.unique.desktop",name:"Unique"}];
    const windows = [{id:"a",appId:"shared",title:"Unknown owner"}, {id:"b",appId:"unique"},
        {id:"c",appId:"org.example.shared"}];
    const dock = Policy.dock(apps, ["ORG.EXAMPLE.UNIQUE.desktop", "org.example.unique.desktop"], windows);
    assert.deepEqual(dock.map(item => item.id), ["org.example.unique.desktop", "shared.desktop", "org.example.shared.desktop"]);
    assert.equal(dock[0].pinned, true);
    assert.equal(dock[0].windows[0].id, "b");
    assert.equal(dock[1].name, "Unknown owner");
    assert.equal(dock[2].name, "One");
});
test("rapid window clicks advance before the previous focus acknowledgement", () => {
    const windows = [{id: "a"}, {id: "b"}, {id: "c"}];
    assert.equal(Policy.nextWindow(windows, "a", "b", "a", 100).id, "c");
    assert.equal(Policy.nextWindow(windows, "c", "b", "a", 100).id, "a");
    assert.equal(Policy.nextWindow(windows, "a", "b", "a", 900).id, "b");
    assert.equal(Policy.nextWindow([], "", "", "", 0), null);
    assert.equal(Policy.influenceAt(0, 100), 1);
    assert.equal(Policy.influenceAt(100, 100), 0);
    assert.equal(Policy.influenceAt(-30, 100), Policy.influenceAt(30, 100));
    assert.notEqual(Policy.sourceKey({desktopEntry: "demo.desktop"}), Policy.sourceKey({appName: "demo"}));
});
test("KWin bridge coalesces snapshots and keeps one idle command request", () => {
    const signal = () => ({callbacks: [], connect(fn) { this.callbacks.push(fn); }});
    const timers = [], publications = [], requests = [];
    const one = {internalId: "{one}", normalWindow: true, desktopFileName: "demo", caption: "One", frameGeometry: {x: 0, y: 0, width: 600, height: 400}, desktops: [], minimizeMode: 0};
    const ignored = {...one, internalId: "skip", skipTaskbar: true};
    const workspace = {windowList: () => [one, ignored], activeWindow: one, desktops: [{id: "desk", name: "Desk"}], currentDesktop: {id: "desk"}};
    const context = vm.createContext({workspace, QTimer: function() { this.timeout = signal(); this.start = () => { this.active = true; }; timers.push(this); },
        callDBus(service, path, iface, method, value) { if (method === "Publish") publications.push(JSON.parse(value)); else requests.push(value); }});
    vm.runInContext(readFileSync(new URL("../packaging/kwin/windows.js", import.meta.url), "utf8"), context);
    assert.equal(publications[0].windows.length, 1);
    assert.equal(publications[0].windows[0].id, "one");
    assert.equal(requests.length, 1);
    context.snapshot();
    assert.equal(publications.length, 1);
    requests[0](JSON.stringify({action: "minimize", id: "one"}));
    assert.equal(one.minimized, true);
    assert.equal(requests.length, 1);
    timers.find(timer => timer.interval === 1).timeout.callbacks[0]();
    assert.equal(requests.length, 2);
});

test("launcher search ranks the expected app first and ignores accents", () => {
    const apps = [
        {id: "org.kde.dolphin.desktop", name: "Dolphin", genericName: "Gestor de archivos", keywords: "files explorer"},
        {id: "firefox.desktop", name: "Firefox", genericName: "Navegador web"},
        {id: "org.mozilla.Thunderbird.desktop", name: "Thunderbird", genericName: "Correo"},
        {id: "libreoffice-calc.desktop", name: "LibreOffice Calc", genericName: "Hoja de cálculo"},
        {id: "libreoffice-writer.desktop", name: "LibreOffice Writer", genericName: "Procesador de textos"},
        {id: "org.kde.konsole.desktop", name: "Konsole", genericName: "Terminal"},
        {id: "spotify.desktop", name: "Spotify", keywords: "music"},
    ];
    const index = Policy.searchIndex(apps);
    const first = query => Policy.search(apps, query, index)[0]?.name;
    assert.equal(first("fire"), "Firefox");
    assert.equal(first("FI"), "Firefox");
    assert.equal(first("navegador"), "Firefox");
    assert.equal(first("calc"), "LibreOffice Calc");
    assert.equal(first("lc"), "LibreOffice Calc");
    assert.equal(first("libre wri"), "LibreOffice Writer");
    assert.equal(first("cálculo"), "LibreOffice Calc");
    assert.equal(first("terminal"), "Konsole");
    assert.equal(first("archivos"), "Dolphin");
    assert.equal(first("music"), "Spotify");
    assert.equal(Policy.search(apps, "zzz", index).length, 0);
    // Sin texto: catálogo completo en su orden; el índice no altera el original.
    assert.equal(Policy.search(apps, "  ", index), apps);
    // Relevancia: "o" coincide con muchos, pero los que empiezan por "o" no
    // existen; gana inicio de palabra y luego el orden del catálogo.
    assert.ok(Policy.search(apps, "office", index).every(app => app.name.startsWith("LibreOffice")));
});

test("search index handles large catalogs quickly", () => {
    const apps = Array.from({length: 2000}, (_, i) => ({id: `app${i}.desktop`, name: `Aplicación ${i}`, keywords: "uno dos"}));
    const index = Policy.searchIndex(apps);
    const started = performance.now();
    for (const q of ["a", "ap", "apl", "apli", "aplic 19", "dos"]) Policy.search(apps, q, index);
    assert.ok(performance.now() - started < 200);
});
