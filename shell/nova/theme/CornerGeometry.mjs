// SPDX-License-Identifier: GPL-3.0-only
// Adapted geometry; see THIRD_PARTY_NOTICES.md. Local adaptation: 2026-10-22.
export const MIN_EXPONENT = 2;
export const MAX_EXPONENT = 8;

export function normalizeExponent(value) {
    if (value === undefined || value === null || !Number.isFinite(value))
        return MIN_EXPONENT
    return Math.min(MAX_EXPONENT, Math.max(MIN_EXPONENT, value))
}

export function clampCornerRadius(radius, halfWidth, halfHeight) {
    const limit = Math.min(halfWidth, halfHeight)
    if (radius === undefined || radius === null || !Number.isFinite(radius))
        return 0
    return Math.min(Math.max(radius, 0), limit)
}

export function squircleNorm(x, y, exponent) {
    const n = normalizeExponent(exponent)
    if (n === 2)
        return Math.sqrt(x * x + y * y)
    if (x <= 0)
        return y
    if (y <= 0)
        return x
    return Math.pow(Math.pow(x, n) + Math.pow(y, n), 1 / n)
}

export function squircleDistance(x, y, halfWidth, halfHeight, radius, exponent) {
    const n = normalizeExponent(exponent)
    const r = clampCornerRadius(radius, halfWidth, halfHeight)
    const qx = Math.abs(x) - halfWidth + r
    const qy = Math.abs(y) - halfHeight + r
    return squircleNorm(Math.max(qx, 0), Math.max(qy, 0), n)
        + Math.min(Math.max(qx, qy), 0) - r
}

export function halfExtentAt(offset, halfWidth, halfHeight, radius, exponent) {
    const n = normalizeExponent(exponent)
    const r = clampCornerRadius(radius, halfWidth, halfHeight)
    const ay = Math.abs(offset)
    if (ay <= halfHeight - r)
        return halfWidth
    const qy = ay - halfHeight + r
    if (qy >= r)
        return halfWidth - r
    const inner = Math.pow(r, n) - Math.pow(qy, n)
    if (!(inner > 0))
        return halfWidth - r
    return halfWidth - r + Math.pow(inner, 1 / n)
}
