// SPDX-License-Identifier: GPL-3.0-or-later
#include "Router.h"
#include "Applications.h"
#include "Preferences.h"
#include "WindowBridge.h"
#include "DesktopActions.h"

#include <QJsonArray>

#include <exception>
#include <memory>

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
    router.m_desktopActions = std::make_shared<DesktopActions>();
    const auto actions = router.m_desktopActions;
    router.add(QStringLiteral("session.action"), [actions](const QJsonObject &p) { return actions->session(p); });
    router.add(QStringLiteral("screenshot.capture"), [actions](const QJsonObject &) { return actions->screenshot(); });
    router.add(QStringLiteral("wallpaper.set"), [actions](const QJsonObject &p) { return actions->wallpaper(p); });
    router.add(QStringLiteral("brightness.get"), [actions](const QJsonObject &) { return actions->brightness(); });
    router.add(QStringLiteral("brightness.set"), [actions](const QJsonObject &p) { return actions->setBrightness(p); });
    router.add(QStringLiteral("system.metrics"), [actions](const QJsonObject &) { return actions->metrics(); });
    router.m_windowBridge = std::make_shared<WindowBridge>();
    const auto windows = router.m_windowBridge;
    router.add(QStringLiteral("windows.list"), [windows](const QJsonObject &) { return windows->snapshot(); });
    router.add(QStringLiteral("window.action"), [windows](const QJsonObject &p) { return windows->action(p); });
    const auto applications = std::make_shared<Applications>();
    const auto preferences = std::make_shared<Preferences>();
    router.add(QStringLiteral("applications.list"), [applications](const QJsonObject &p) { return applications->list(p); });
    router.add(QStringLiteral("application.launch"), [applications](const QJsonObject &p) { return applications->launch(p); });
    router.add(QStringLiteral("settings.get"), [preferences](const QJsonObject &) { return preferences->read(); });
    router.add(QStringLiteral("settings.patch"), [preferences](const QJsonObject &p) { return preferences->patch(p); });
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
