// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QJsonObject>
#include <QStringList>

#include <chrono>

namespace nova {

// Lista los globals que anuncia el compositor Wayland de la sesión, sin
// crear superficies ni ligar ningún protocolo. Acotado en tiempo: un
// compositor que no responde produce "available": false, nunca un bloqueo.
struct WaylandGlobals {
    bool available = false;
    QString error;
    QStringList interfaces; // ordenadas, sin duplicados
};

WaylandGlobals probeWaylandGlobals(std::chrono::milliseconds timeout);

// Resultado de compositor.capabilities (ver docs/CONTRATO-IPC-v1.md).
QJsonObject compositorCapabilities(const WaylandGlobals &globals);

} // namespace nova
