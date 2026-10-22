// SPDX-License-Identifier: GPL-3.0-or-later
// Original vectors (not extracted Apple artwork), Liquid Glass monochrome.
export const folders = Object.freeze({
    folder: "", "folder-open": "", "inode-directory": "",
    "folder-documents": "M25 30h10l4 4v12H25zM35 30v5h4M29 39h6M29 42h6",
    "folder-download": "M32 29v14M26 37l6 6 6-6M25 47h14",
    "folder-pictures": "M23 30h18v16H23zM23 42l5-5 5 5 3-3 5 5M36 34h.01",
    "folder-music": "M29 42V30l11-2v12M29 42a3 3 0 1 1-3-3h3M40 40a3 3 0 1 1-3-3h3",
    "folder-videos": "M25 30h10v16H25zM35 35l7-4v14l-7-4",
    "folder-remote": "M22 32h20v13H22zM26 38h.01M30 38h.01M35 38h.01M39 38h.01",
    "user-home": "M22 37l10-9 10 9M25 35v12h14V35M30 47v-8h4v8",
    "folder-desktop": "M22 30h20v14H22zM28 48h8M32 44v4",
    "folder-publicshare": "M28 37a3 3 0 1 0 0-6 3 3 0 0 0 0 6M36 37a3 3 0 1 0 0-6 3 3 0 0 0 0 6M22 46c0-10 12-10 12 0M33 40c5-3 9 0 9 6",
    "folder-templates": "M25 29h14v18H25zM28 33h8M28 37h8M28 41h5"
});
export const folderNames = Object.freeze(Object.keys(folders));
// Synonyms used by Dolphin, KIO and the inherited library. They point at a
// role so every common folder stays monochrome. Named colours (folder-red,
// folder_color_*) and states (locked, encrypted, trash) keep their own art.
export const folderAliases = Object.freeze(Object.fromEntries([
    ...["folder-downloads", "folder_download", "folder_downloads", "folders-downloads", "folder-download-open"].map(alias => [alias, "folder-download"]),
    ...["folder-documents-open", "folders-documents", "folder-text", "folder-txt", "folder-notes", "folder-book"].map(alias => [alias, "folder-documents"]),
    ...["folder-pictures-open", "folder-picture", "folder-image", "folder-images", "folder_images", "folder_pictures", "folder-photo", "folder-photos", "folder-camera", "user-images", "user-pictures"].map(alias => [alias, "folder-pictures"]),
    ...["folder-music-open", "folders-music", "folder-sound", "folder-podcast"].map(alias => [alias, "folder-music"]),
    ...["folder-videos-open", "folders-videos", "folder-video", "folder-videocamera"].map(alias => [alias, "folder-videos"]),
    ...["folder-remote-open", "folder-remote-ftp", "folder-remote-nfs", "folder-remote-smb", "folder-remote-ssh", "folder-network", "folder-cloud", "folder-gdrive", "folder-dropbox", "folder-onedrive", "folder-owncloud"].map(alias => [alias, "folder-remote"]),
    ...["folder-home", "folder_home", "user-home-open"].map(alias => [alias, "user-home"]),
    ...["user-desktop"].map(alias => [alias, "folder-desktop"]),
    ...["folder-public", "folder-publicshare-open", "folders-publicshare", "user-share"].map(alias => [alias, "folder-publicshare"]),
    ...["folder-templates-open"].map(alias => [alias, "folder-templates"]),
    ...["folder_open", "folder-drag-accept"].map(alias => [alias, "folder-open"]),
    ...["folder_color_default", "folder-development", "folder-code", "folder-projects", "folder-git", "folder-github", "folder-build", "folder-script", "folder-html", "folder_html", "folder-temp", "folder-recent", "folder-favorites", "folder-bookmark", "folder-bookmarks", "folder-games", "folder-steam", "folder-root", "folder-library", "folder-log", "folder-tar"].map(alias => [alias, "folder"]),
]));

export function folderSvg(name, mode = "default", small = false) {
    if (!Object.hasOwn(folders, name)) throw new TypeError("Unknown folder role");
    if (!["default", "dark", "clear", "tinted"].includes(mode)) throw new TypeError("Unknown appearance");
    const dark = mode === "dark";
    const clear = mode === "clear";
    // Liquid Glass monocromo: perla en claro, grafito en oscuro; sin tinte azul.
    const tinted = mode === "tinted";
    const top = dark ? "#55585f" : tinted ? "#b8bbc2" : clear ? "#f3f4f6" : "#e3e5e9";
    const bottom = dark ? "#303237" : tinted ? "#8a8d95" : clear ? "#d5d8dd" : "#b6bac2";
    const ink = dark ? "#eceef2" : tinted ? "#1d1f24" : "#33363d";
    const symbol = dark ? "#d9dbe0" : "#3a3d44";
    const outline = 'M7 19v-4a4 4 0 0 1 4-4h14l5 5h23a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H11a4 4 0 0 1-4-4z';
    const badge = folders[name];
    const open = name === "folder-open";
    // Optical small-size rendition: semantic symbol, without subpixel effects.
    if (small) return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="'
        + (badge || outline) + '" fill="none" stroke="'
        + symbol
        + '" stroke-width="' + (badge ? 2.2 : 4) + '" stroke-linecap="round" stroke-linejoin="round"'
        + (badge ? ' transform="translate(-32 -44) scale(2)"' : "") + '/>'
        + (open ? '<path d="M10 25h47l-6 27H8z" fill="none" stroke="' + symbol
            + '" stroke-width="4" stroke-linejoin="round"/>' : "") + '</svg>';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs>'
        + '<linearGradient id="front" x2="0" y2="1"><stop stop-color="' + top
        + '"/><stop offset="1" stop-color="' + bottom + '"/></linearGradient></defs>'
        + '<path d="' + outline + '" fill="' + bottom + '" fill-opacity="' + (clear ? 0.45 : 1) + '"/>'
        + (open ? '<path d="M14 25h43l-5 24a4 4 0 0 1-4 3H11a4 4 0 0 1-4-5l4-19a4 4 0 0 1 3-3z"'
            : '<rect x="8" y="19" width="48" height="33" rx="3"')
        + ' fill="url(#front)" fill-opacity="' + (clear ? 0.45 : 1) + '" stroke="'
        + ink + '" stroke-opacity=".18" stroke-width="1"/>'
        + '<path d="' + (open ? 'M15 26h38' : 'M12 20h40') + '" stroke="#ffffff" stroke-opacity=".75" stroke-width="1.5"/>'
        + (badge ? '<path d="' + badge + '" fill="none" stroke="' + ink
            + '" stroke-width="1.8" stroke-opacity=".65" stroke-linecap="round" stroke-linejoin="round"/>' : "")
        + '</svg>';
}
