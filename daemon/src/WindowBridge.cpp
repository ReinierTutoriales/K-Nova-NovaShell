// SPDX-License-Identifier: GPL-3.0-or-later
#include "WindowBridge.h"
#include <QCoreApplication>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>
#include <QFileInfo>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QStandardPaths>

namespace nova {
namespace {
const QString Service = QStringLiteral("org.nova.Shell");
const QString Object = QStringLiteral("/Windows");
const QString KWin = QStringLiteral("org.kde.KWin");
}
WindowBridge::WindowBridge() : m_watcher(KWin, QDBusConnection::sessionBus(), QDBusServiceWatcher::WatchForOwnerChange) {
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.registerService(Service)) return;
    m_registered = bus.registerObject(Object, this, QDBusConnection::ExportScriptableSlots);
    if (!m_registered) { bus.unregisterService(Service); return; }
    m_heartbeat.setSingleShot(true);
    m_heartbeat.setInterval(15000);
    connect(&m_heartbeat, &QTimer::timeout, this, [this] { release(); });
    connect(&m_watcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
        [this](const QString &, const QString &, const QString &) { load(); });
    QTimer::singleShot(0, this, [this] { load(); });
}
WindowBridge::~WindowBridge() {
    if (m_registered) {
        release();
        auto bus = QDBusConnection::sessionBus();
        QDBusMessage unload = QDBusMessage::createMethodCall(KWin, QStringLiteral("/Scripting"),
            QStringLiteral("org.kde.kwin.Scripting"), QStringLiteral("unloadScript"));
        unload << QStringLiteral("nova-windows");
        bus.send(unload);
        bus.unregisterObject(Object);
        bus.unregisterService(Service);
    }
}
void WindowBridge::load() {
    release();
    m_snapshot = QJsonObject();
    const auto bus = QDBusConnection::sessionBus();
    if (!bus.interface()) return;
    const QDBusReply<QString> owner = bus.interface()->serviceOwner(KWin);
    m_owner = owner.isValid() ? owner.value() : QString();
    emit changed(std::get<QJsonObject>(snapshot()));
    if (m_owner.isEmpty()) return;
    QString script = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                                           QStringLiteral("novashell/kwin/windows.js"));
    for (const auto &relative : {QStringLiteral("/../share/novashell/kwin/windows.js"),
                                QStringLiteral("/../../packaging/kwin/windows.js")}) {
        if (script.isEmpty()) {
            const QString candidate = QCoreApplication::applicationDirPath() + relative;
            if (QFileInfo(candidate).isReadable()) script = QFileInfo(candidate).absoluteFilePath();
        }
    }
    if (script.isEmpty()) return;
    QDBusInterface scripting(KWin, QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"), bus);
    scripting.setTimeout(1000);
    // Unload only this script; never change another shell's KWin configuration.
    scripting.call(QStringLiteral("unloadScript"), QStringLiteral("nova-windows"));
    const auto pending = scripting.asyncCall(QStringLiteral("loadScript"), script, QStringLiteral("nova-windows"));
    auto *watcher = new QDBusPendingCallWatcher(pending, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [watcher, bus](QDBusPendingCallWatcher *) {
        const QDBusPendingReply<int> loaded = *watcher;
        if (!loaded.isError() && loaded.value() >= 0) {
            QDBusInterface scripting(KWin, QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"), bus);
            scripting.asyncCall(QStringLiteral("start"));
        }
        watcher->deleteLater();
    });
}
bool WindowBridge::authorized() const {
    return calledFromDBus() && !m_owner.isEmpty() && message().service() == m_owner;
}
void WindowBridge::Publish(const QString &payload) {
    if (!authorized() || payload.size() > 60000 || payload.toUtf8().size() > 60000) return;
    const QJsonObject object = QJsonDocument::fromJson(payload.toUtf8()).object();
    if (!object.value(QStringLiteral("windows")).isArray()
        || object.value(QStringLiteral("windows")).toArray().size() > 128) return;
    if (object != m_snapshot) {
        m_snapshot = object;
        emit changed(std::get<QJsonObject>(snapshot()));
    }
}
QString WindowBridge::TakeCommand() {
    if (!authorized()) return {};
    release();
    setDelayedReply(true);
    m_waiter = message();
    m_waiting = true;
    m_heartbeat.start();
    return {};
}
void WindowBridge::release(const QString &command) {
    if (!m_waiting) return;
    m_heartbeat.stop();
    QDBusConnection::sessionBus().send(m_waiter.createReply(QVariantList{command}));
    m_waiting = false;
}
Reply WindowBridge::snapshot() const {
    QJsonObject value = m_snapshot;
    value.insert(QStringLiteral("available"), !m_snapshot.isEmpty() && !m_owner.isEmpty());
    if (!value.contains(QStringLiteral("windows"))) value.insert(QStringLiteral("windows"), QJsonArray());
    if (!value.contains(QStringLiteral("desktops"))) value.insert(QStringLiteral("desktops"), QJsonArray());
    return value;
}
Reply WindowBridge::action(const QJsonObject &payload) {
    const QString action = payload.value(QStringLiteral("action")).toString();
    const QString id = payload.value(QStringLiteral("id")).toString();
    QJsonArray ids = payload.value(QStringLiteral("ids")).toArray();
    if (ids.isEmpty()) ids.append(id);
    const QStringList allowed{"activate", "minimize", "maximize", "close", "desktop"};
    if (!allowed.contains(action) || id.size() > 128 || ids.size() > 32
        || (action == QLatin1String("desktop") && ids.size() != 1))
        return protocol::Error{QStringLiteral("invalid-request"), QStringLiteral("acción de ventana inválida"), false};
    const QString key = action == QLatin1String("desktop") ? QStringLiteral("desktops") : QStringLiteral("windows");
    for (const auto &target : ids) {
        bool found = false;
        if (!target.isString() || target.toString().size() > 128) return protocol::Error{
            QStringLiteral("invalid-request"), QStringLiteral("identificador inválido"), false};
        for (const auto &entry : m_snapshot.value(key).toArray())
            if (entry.toObject().value(QStringLiteral("id")) == target) found = true;
        if (!found) return protocol::Error{QStringLiteral("invalid-request"), QStringLiteral("ventana o escritorio inexistente"), false};
    }
    if (!m_waiting) return protocol::Error{QStringLiteral("unavailable"), QStringLiteral("KWin no está listo"), true};
    release(QString::fromUtf8(QJsonDocument(payload).toJson(QJsonDocument::Compact)));
    return QJsonObject{{QStringLiteral("accepted"), true}};
}
}
