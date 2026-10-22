// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.nova.theme

// Tarjeta de contenido dentro de un panel de vidrio (ventanas, notificaciones
// del historial). Relleno plano, sin vidrio: el vidrio es de la capa de
// navegación, no del contenido (Apple HIG, Liquid Glass).
Rectangle {
    radius: Theme.radius.lg
    antialiasing: true
    color: Theme.color.cardFill
    border.width: Theme.space.hairline
    border.color: Theme.color.controlBorder
}
