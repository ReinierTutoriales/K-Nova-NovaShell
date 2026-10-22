// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.bar

// Raíz del escritorio: crea una barra por pantalla y la retira sola cuando
// una pantalla se desconecta (Variants sigue a Quickshell.screens).
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
