// SPDX-License-Identifier: GPL-3.0-or-later
#include "Router.h"

#include <QJsonArray>

#include <exception>

namespace nova {

namespace {
const QString CapabilitiesOperation = QStringLiteral("platform.capabilities");
} // namespace

bool Router::add(const QString &operation, Handler handler)
{
    if (!protocol::isValidOperationName(operation) || !handler
        || operation == CapabilitiesOperation || m_handlers.contains(operation)) {
        return false;
    }
    m_handlers.insert(operation, std::move(handler));
    return true;
}

Reply Router::dispatch(const protocol::Request &request) const
{
    // Integrada en el router: así la lista siempre refleja la tabla real.
    if (request.operation == CapabilitiesOperation) {
        return QJsonObject{
            {QStringLiteral("protocol"), protocol::Version},
            {QStringLiteral("operations"), QJsonArray::fromStringList(operations())},
        };
    }

    const auto it = m_handlers.constFind(request.operation);
    if (it == m_handlers.constEnd()) {
        return protocol::Error{QString::fromLatin1(protocol::code::UnknownOperation),
            QStringLiteral("operación desconocida: %1").arg(request.operation), false};
    }
    // Un manejador defectuoso no debe tumbar el daemon de toda la sesión.
    try {
        return it.value()(request.payload);
    } catch (const std::exception &e) {
        return protocol::Error{QString::fromLatin1(protocol::code::Internal),
            QString::fromUtf8(e.what()), true};
    } catch (...) {
        return protocol::Error{QString::fromLatin1(protocol::code::Internal),
            QStringLiteral("error interno"), true};
    }
}

QStringList Router::operations() const
{
    QStringList list = m_handlers.keys();
    list.append(CapabilitiesOperation);
    list.sort();
    return list;
}

Router Router::makeDefault()
{
    Router router;
    router.add(QStringLiteral("platform.ping"), [](const QJsonObject &) -> Reply {
        return QJsonObject{{QStringLiteral("ready"), true}};
    });
    router.add(QStringLiteral("platform.version"), [](const QJsonObject &) -> Reply {
        return QJsonObject{
            {QStringLiteral("version"), QStringLiteral(NOVA_VERSION)},
            {QStringLiteral("protocol"), protocol::Version},
        };
    });
    return router;
}

} // namespace nova
