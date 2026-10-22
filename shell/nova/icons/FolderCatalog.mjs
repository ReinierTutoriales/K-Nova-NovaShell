// SPDX-License-Identifier: GPL-3.0-or-later
// Original vectors. Golden Gate visual target; not extracted Apple artwork.
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

export function folderSvg(name, mode = "default", small = false) {
    if (!Object.hasOwn(folders, name)) throw new TypeError("Unknown folder role");
    if (!["default", "dark", "clear", "tinted"].includes(mode)) throw new TypeError("Unknown appearance");
    const dark = mode === "dark";
    const clear = mode === "clear";
    const top = dark ? "#395467" : mode === "tinted" ? "#86acf4" : clear ? "#e3edf5" : "#85d0ed";
    const bottom = dark ? "#253e51" : mode === "tinted" ? "#487cd3" : clear ? "#c3d5e4" : "#57a7cf";
    const ink = dark ? "#dceef9" : clear ? "#3a566b" : "#184f72";
    const outline = 'M7 19v-4a4 4 0 0 1 4-4h14l5 5h23a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H11a4 4 0 0 1-4-4z';
    const badge = folders[name];
    const open = name === "folder-open";
    // Optical small-size rendition: semantic symbol, without subpixel effects.
    if (small) return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="'
        + (badge || outline) + '" fill="none" stroke="'
        + (dark ? "#76bcff" : clear ? "#3a566b" : "#087bff")
        + '" stroke-width="' + (badge ? 2.2 : 4) + '" stroke-linecap="round" stroke-linejoin="round"'
        + (badge ? ' transform="translate(-32 -44) scale(2)"' : "") + '/>'
        + (open ? '<path d="M10 25h47l-6 27H8z" fill="none" stroke="' + (dark ? "#76bcff" : "#087bff")
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
