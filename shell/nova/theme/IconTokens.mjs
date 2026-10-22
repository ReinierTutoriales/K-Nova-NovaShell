// SPDX-License-Identifier: GPL-3.0-or-later
// Shared by live QML and the build-time freedesktop theme exporter.
export const palettes = Object.freeze({
    blue: ["#68b9ff", "#1264e8"], purple: ["#b197ff", "#7148da"],
    orange: ["#ffc56c", "#e66b1e"], green: ["#78dfa4", "#159b68"],
    pink: ["#ff9ecb", "#d54283"], slate: ["#aab7cc", "#596b86"]
});
export function styleForPalette(palette, dark = false) {
    return {
        palette: palettes[palette], ink: dark ? "#f5f6fa" : "#17191e",
        tile: dark ? "#303239" : "#ffffff", tint: "#3478f6",
        white: "#ffffff", darkTile: "#22252e", darkEdge: "#5c6270",
        lightEdge: "#ffffff", highlight: "#ffffff", clearOpacity: 0.32
    };
}
