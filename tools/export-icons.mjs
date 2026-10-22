// SPDX-License-Identifier: GPL-3.0-or-later
// Build-time only. NovaShell has no Node.js runtime dependency.
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { resolve, join } from "node:path";
import * as Catalog from "../shell/nova/icons/IconCatalog.mjs";
import { folderNames, folderSvg } from "../shell/nova/icons/FolderCatalog.mjs";
import { pathToFileURL } from "node:url";
import { styleForPalette } from "../shell/nova/theme/IconTokens.mjs";

export function styleFor(name, dark = false) {
    return styleForPalette(Catalog.application(name).palette, dark);
}
export function decode(source) {
    return decodeURIComponent(source.slice(source.indexOf(",") + 1));
}
export function exportTheme(destination) {
    const fileManager = readFileSync(new URL("../assets/icon-sources/file-manager.svg", import.meta.url), "utf8");
    // Subpixel Gaussian filters trigger invalid intermediate buffers in Qt SVG
    // at 16 px. Keep geometry/colors; omit only those effects at that size.
    const fileManagerSmall = fileManager.replace(/<filter\b[\s\S]*?<\/filter>/g, "")
        .replace(/\sfilter="url\(#[^"]+\)"/g, "");
    for (const mode of ["default", "dark", "clear", "tinted"]) {
        const name = "NovaGlass" + (mode === "default" ? "" : "-" + mode);
        const directory = join(destination, name);
        mkdirSync(join(directory, "scalable/apps"), { recursive: true });
        mkdirSync(join(directory, "16x16/apps"), { recursive: true });
        mkdirSync(join(directory, "scalable/places"), { recursive: true });
        mkdirSync(join(directory, "16x16/places"), { recursive: true });
        copyFileSync(new URL("../LICENSE", import.meta.url), join(directory, "COPYING"));
        copyFileSync(new URL("../THIRD_PARTY_NOTICES.md", import.meta.url),
            join(directory, "THIRD_PARTY_NOTICES.md"));
        const actions = mode === "default";
        if (actions) mkdirSync(join(directory, "scalable/actions"), { recursive: true });
        writeFileSync(join(directory, "index.theme"),
            "[Icon Theme]\nName=" + name + "\nComment=NovaShell layered vector icons\n"
            + "Inherits=" + (mode === "dark" ? "NovaGlass-System-dark,NovaGlass,breeze,hicolor"
                : actions ? "NovaGlass-System-light,breeze,hicolor"
                : "NovaGlass,NovaGlass-System-light,breeze,hicolor")
            + "\nDirectories=16x16/apps,scalable/apps,16x16/places,scalable/places" + (actions ? ",scalable/actions" : "") + "\n\n"
            + "[16x16/apps]\nSize=16\nType=Fixed\nContext=Applications\n\n"
            + "[16x16/places]\nSize=16\nType=Fixed\nContext=Places\n\n"
            + "[scalable/places]\nSize=64\nMinSize=22\nMaxSize=256\nType=Scalable\nContext=Places\n\n"
            + "[scalable/apps]\nSize=64\nMinSize=16\nMaxSize=256\nType=Scalable\nContext=Applications\n"
            + (actions ? "\n[scalable/actions]\nSize=24\nMinSize=16\nMaxSize=64\nType=Scalable\nContext=Actions\n" : ""));
        for (const id of Catalog.applicationNames)
            writeFileSync(join(directory, "scalable/apps", "nova-" + id + ".svg"),
                "<!-- SPDX-License-Identifier: GPL-3.0-only; see THIRD_PARTY_NOTICES.md -->\n"
                + decode(Catalog.applicationSource(id, mode, styleFor(id, mode === "dark"))) + "\n");
        for (const id of ["org.kde.dolphin", "system-file-manager", "dolphin"]) {
            writeFileSync(join(directory, "scalable/apps", id + ".svg"), fileManager);
            writeFileSync(join(directory, "16x16/apps", id + ".svg"), fileManagerSmall);
        }
        for (const id of folderNames) {
            const notice = "<!-- SPDX-License-Identifier: GPL-3.0-or-later -->\n";
            writeFileSync(join(directory, "scalable/places", id + ".svg"), notice + folderSvg(id, mode) + "\n");
            writeFileSync(join(directory, "16x16/places", id + ".svg"), notice + folderSvg(id, mode, true) + "\n");
        }
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
