// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "Protocol.h"

#include <QJsonObject>
#include <QMap>
#include <QStringList>

#include <functional>
#include <variant>
#include <memory>

namespace nova {
class WindowBridge;
class DesktopActions;

// Respuesta de un manejador: un resultado o un error, nunca ambos.
using Reply = std::variant<QJsonObject, protocol::Error>;
using Handler = std::function<Reply(const QJsonObject &payload)>;

// Tabla de operaciones permitidas. Todo lo que el shell puede pedir al
// sistema pasa por aquí: si no está registrado, no existe.
class Router
{
public:
    // Devuelve false si la operación ya existía o el nombre es inválido.
    bool add(const QString &operation, Handler handler);
    Reply dispatch(const protocol::Request &request) const;
    QStringList operations() const;

    // Router con las operaciones base de v1 (platform.*).
    static Router makeDefault();
    WindowBridge *windowBridge() const { return m_windowBridge.get(); }
    DesktopActions *desktopActions() const { return m_desktopActions.get(); }

private:
    QMap<QString, Handler> m_handlers;
    std::shared_ptr<WindowBridge> m_windowBridge;
    std::shared_ptr<DesktopActions> m_desktopActions;
};

} // namespace nova
