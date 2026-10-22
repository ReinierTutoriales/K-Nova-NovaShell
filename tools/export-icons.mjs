// SPDX-License-Identifier: GPL-3.0-or-later
// Build-time only. NovaShell has no Node.js runtime dependency.
import { copyFileSync, mkdirSync, writeFileSync } from "node:fs";
import { resolve, join } from "node:path";
import * as Catalog from "../shell/nova/icons/IconCatalog.mjs";
import { pathToFileURL } from "node:url";
import { styleForPalette } from "../shell/nova/theme/IconTokens.mjs";

export function styleFor(name, dark = false) {
    return styleForPalette(Catalog.application(name).palette, dark);
}
export function decode(source) {
    return decodeURIComponent(source.slice(source.indexOf(",") + 1));
}
export function exportTheme(destination) {
    for (const mode of ["default", "dark", "clear", "tinted"]) {
        const name = "NovaGlass" + (mode === "default" ? "" : "-" + mode);
        const directory = join(destination, name);
        mkdirSync(join(directory, "scalable/apps"), { recursive: true });
        copyFileSync(new URL("../LICENSE", import.meta.url), join(directory, "COPYING"));
        copyFileSync(new URL("../THIRD_PARTY_NOTICES.md", import.meta.url),
            join(directory, "THIRD_PARTY_NOTICES.md"));
        const actions = mode === "default";
        if (actions) mkdirSync(join(directory, "scalable/actions"), { recursive: true });
        writeFileSync(join(directory, "index.theme"),
            "[Icon Theme]\nName=" + name + "\nComment=NovaShell layered vector icons\n"
            + "Inherits=" + (actions ? "breeze,hicolor" : "NovaGlass,breeze,hicolor")
            + "\nDirectories=scalable/apps" + (actions ? ",scalable/actions" : "") + "\n\n"
            + "[scalable/apps]\nSize=64\nMinSize=16\nMaxSize=256\nType=Scalable\nContext=Applications\n"
            + (actions ? "\n[scalable/actions]\nSize=24\nMinSize=16\nMaxSize=64\nType=Scalable\nContext=Actions\n" : ""));
        for (const id of Catalog.applicationNames)
            writeFileSync(join(directory, "scalable/apps", "nova-" + id + ".svg"),
                "<!-- SPDX-License-Identifier: GPL-3.0-only; see THIRD_PARTY_NOTICES.md -->\n"
                + decode(Catalog.applicationSource(id, mode, styleFor(id, mode === "dark"))) + "\n");
        if (actions) {
            for (const id of Catalog.symbolNames)
                writeFileSync(join(directory, "scalable/actions", "nova-" + id + ".svg"),
                    "<!-- SPDX-License-Identifier: GPL-3.0-only; see THIRD_PARTY_NOTICES.md -->\n"
                    + decode(Catalog.symbolSource(id, "#17191e")) + "\n");
        }
    }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href)
    exportTheme(resolve(process.argv[2] || "build/icon-themes"));
