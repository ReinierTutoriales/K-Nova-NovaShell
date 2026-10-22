// SPDX-License-Identifier: GPL-3.0-or-later
#include "DesktopActions.h"
#include <QDBusConnectionInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QMimeDatabase>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QUuid>
#include <algorithm>
#include <memory>

namespace nova {
namespace {
protocol::Error invalid(const QString &message) { return {QStringLiteral("invalid-request"), message, false}; }
bool available(const QDBusConnection &bus, const QString &service) {
    return bus.isConnected() && bus.interface() && bus.interface()->isServiceRegistered(service).value();
}
QDBusMessage method(const QString &service, const QString &path, const QString &interface, const QString &name) {
    auto message = QDBusMessage::createMethodCall(service, path, interface, name);
    message.setAutoStartService(false);
    return message;
}
}
Reply DesktopActions::dispatch(const QDBusConnection &bus, const QDBusMessage &message) {
    if (m_pending >= 4 || !available(bus, message.service()))
        return protocol::Error{QStringLiteral("unavailable"), QStringLiteral("servicio no disponible o ocupado"), true};
    const QString token = QUuid::createUuid().toString(QUuid::WithoutBraces);
    ++m_pending;
    auto *watcher = new QDBusPendingCallWatcher(bus.asyncCall(message, 30000), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, token](QDBusPendingCallWatcher *) {
        const QDBusMessage reply = watcher->reply();
        const bool ok = reply.type() != QDBusMessage::ErrorMessage;
        --m_pending;
        emit event(QStringLiteral("system.action"), {{QStringLiteral("token"), token},
            {QStringLiteral("ok"), ok},
            {QStringLiteral("message"), ok ? QString() : reply.errorMessage().left(512)}});
        watcher->deleteLater();
    });
    return QJsonObject{{QStringLiteral("accepted"), true}, {QStringLiteral("token"), token}};
}
Reply DesktopActions::session(const QJsonObject &payload) {
    const QString action = payload.value(QStringLiteral("action")).toString();
    if (action == QLatin1String("lock")) {
        const auto message = method(QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("/ScreenSaver"),
            QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("Lock"));
        return dispatch(QDBusConnection::sessionBus(), message);
    }
    if (action == QLatin1String("logout")) {
        auto message = method(QStringLiteral("org.freedesktop.systemd1"), QStringLiteral("/org/freedesktop/systemd1"),
            QStringLiteral("org.freedesktop.systemd1.Manager"), QStringLiteral("StopUnit"));
        message << QStringLiteral("graphical-session.target") << QStringLiteral("replace");
        return dispatch(QDBusConnection::sessionBus(), message);
    }
    const QHash<QString, QString> methods{{"suspend", "Suspend"}, {"reboot", "Reboot"}, {"poweroff", "PowerOff"}};
    if (!methods.contains(action)) return invalid(QStringLiteral("acción de sesión inválida"));
    auto message = method(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"),
        QStringLiteral("org.freedesktop.login1.Manager"), methods.value(action));
    message << true;
    return dispatch(QDBusConnection::systemBus(), message);
}
Reply DesktopActions::screenshot() {
    const QString executable = QStandardPaths::findExecutable(QStringLiteral("spectacle"));
    if (executable.isEmpty()) return protocol::Error{QStringLiteral("unavailable"), QStringLiteral("Spectacle no está instalado"), false};
    const bool launched = QProcess::startDetached(executable, QStringList{QStringLiteral("--region")});
    return QJsonObject{{QStringLiteral("launched"), launched}};
}
Reply DesktopActions::wallpaper(const QJsonObject &payload) {
    const QUrl url(payload.value(QStringLiteral("url")).toString());
    const int screen = payload.value(QStringLiteral("screen")).toInt(-1);
    const QFileInfo file(url.toLocalFile());
    if (!url.isLocalFile() || url.toString().size() > 4096 || screen < 0 || screen > 31
        || !file.isFile() || !file.isReadable() || file.size() > 64 * 1024 * 1024
        || !QMimeDatabase().mimeTypeForFile(file, QMimeDatabase::MatchContent).name().startsWith(QLatin1String("image/")))
        return invalid(QStringLiteral("imagen local o pantalla inválida"));
    auto message = method(QStringLiteral("org.kde.plasmashell"), QStringLiteral("/PlasmaShell"),
        QStringLiteral("org.kde.PlasmaShell"), QStringLiteral("setWallpaper"));
    message << QStringLiteral("org.kde.image") << QVariantMap{{QStringLiteral("Image"), url.toString()}} << static_cast<quint32>(screen);
    return dispatch(QDBusConnection::sessionBus(), message);
}
Reply DesktopActions::brightness() {
    if (!m_brightness.contains(QStringLiteral("available")))
        m_brightness = {{QStringLiteral("available"), false}, {QStringLiteral("displays"), QJsonArray()}};
    if (m_brightnessBusy || (m_brightnessAge.isValid() && m_brightnessAge.elapsed() < 1000)) return m_brightness;
    const auto bus = QDBusConnection::sessionBus();
    QString service;
    for (const auto &candidate : {QStringLiteral("org.kde.ScreenBrightness"), QStringLiteral("org.kde.Solid.PowerManagement")})
        if (available(bus, candidate)) { service = candidate; break; }
    m_brightnessAge.start();
    if (service.isEmpty()) {
        m_displays.clear();
        m_brightness = {{QStringLiteral("available"), false}, {QStringLiteral("displays"), QJsonArray()}};
        return m_brightness;
    }
    m_brightnessBusy = true;
    auto message = method(service, QStringLiteral("/org/kde/ScreenBrightness"), QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("Get"));
    message << QStringLiteral("org.kde.ScreenBrightness") << QStringLiteral("DisplaysDBusNames");
    auto *watcher = new QDBusPendingCallWatcher(bus.asyncCall(message, 1500), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, service, bus](QDBusPendingCallWatcher *) {
        const QDBusPendingReply<QDBusVariant> result = *watcher;
        watcher->deleteLater();
        if (result.isError()) { m_displays.clear(); finishBrightness(); return; }
        const QStringList ids = result.value().variant().toStringList().mid(0, 8);
        m_displays.clear();
        if (ids.isEmpty()) finishBrightness();
        const auto pending = std::make_shared<int>(static_cast<int>(ids.size()));
        for (const auto &id : ids) {
            if (!QRegularExpression(QStringLiteral("^[A-Za-z0-9_]+$")).match(id).hasMatch()) {
                if (--*pending == 0) finishBrightness();
                continue;
            }
            auto request = method(service, QStringLiteral("/org/kde/ScreenBrightness/") + id,
                QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("GetAll"));
            request << QStringLiteral("org.kde.ScreenBrightness.Display");
            auto *display = new QDBusPendingCallWatcher(bus.asyncCall(request, 1500), this);
            connect(display, &QDBusPendingCallWatcher::finished, this, [this, display, id, service, pending](QDBusPendingCallWatcher *) {
                const QDBusPendingReply<QVariantMap> reply = *display;
                if (!reply.isError()) {
                    const auto properties = reply.value();
                    const int maximum = properties.value(QStringLiteral("MaxBrightness")).toInt();
                    if (maximum > 0) m_displays.insert(id, {{QStringLiteral("id"), id}, {QStringLiteral("service"), service},
                        {QStringLiteral("name"), properties.value(QStringLiteral("Label")).toString().left(128)},
                        {QStringLiteral("maximum"), maximum},
                        {QStringLiteral("percent"), qBound(0, qRound(properties.value(QStringLiteral("Brightness")).toDouble() * 100 / maximum), 100)}});
                }
                display->deleteLater();
                if (--*pending == 0) {
                    finishBrightness();
                }
            });
        }
    });
    return m_brightness;
}
void DesktopActions::finishBrightness() {
    m_brightnessBusy = false;
    QJsonArray values;
    for (auto entry : m_displays) {
        entry.remove(QStringLiteral("service"));
        entry.remove(QStringLiteral("maximum"));
        values.append(entry);
    }
    m_brightness = {{QStringLiteral("available"), !values.isEmpty()}, {QStringLiteral("displays"), values}};
    emit event(QStringLiteral("brightness.changed"), m_brightness);
}
Reply DesktopActions::setBrightness(const QJsonObject &payload) {
    const QString id = payload.value(QStringLiteral("id")).toString();
    const QJsonValue percent = payload.value(QStringLiteral("percent"));
    if (!m_displays.contains(id) || !percent.isDouble() || percent.toDouble() != percent.toInt(-1)
        || percent.toInt() < 1 || percent.toInt() > 100) return invalid(QStringLiteral("pantalla o porcentaje inválido"));
    const auto display = m_displays.value(id);
    auto message = method(display.value(QStringLiteral("service")).toString(), QStringLiteral("/org/kde/ScreenBrightness/") + id,
        QStringLiteral("org.kde.ScreenBrightness.Display"), QStringLiteral("SetBrightness"));
    message << qRound(percent.toDouble() * display.value(QStringLiteral("maximum")).toInt() / 100) << static_cast<quint32>(0);
    m_brightnessAge.invalidate();
    return dispatch(QDBusConnection::sessionBus(), message);
}
Reply DesktopActions::metrics() {
    if (m_metricsAge.isValid() && m_metricsAge.elapsed() < 1000) return m_metrics;
    QFile cpu(QStringLiteral("/proc/stat")), memory(QStringLiteral("/proc/meminfo"));
    if (!cpu.open(QIODevice::ReadOnly) || !memory.open(QIODevice::ReadOnly))
        return QJsonObject{{QStringLiteral("available"), false}};
    const auto fields = cpu.readLine(4096).simplified().split(' ');
    quint64 total = 0;
    for (qsizetype i = 1; i < fields.size() && i <= 8; ++i) total += fields.at(i).toULongLong();
    const quint64 idle = fields.value(4).toULongLong() + fields.value(5).toULongLong();
    const double busy = m_cpuTotal > 0 && total > m_cpuTotal && idle >= m_cpuIdle
        ? 100 * (1 - static_cast<double>(idle - m_cpuIdle) / static_cast<double>(total - m_cpuTotal)) : 0;
    m_cpuTotal = total; m_cpuIdle = idle;
    quint64 availableMemory = 0, totalMemory = 0;
    for (const auto &line : memory.read(32768).split('\n')) {
        const auto values = line.simplified().split(' ');
        if (values.value(0) == "MemTotal:") totalMemory = values.value(1).toULongLong() * 1024;
        if (values.value(0) == "MemAvailable:") availableMemory = values.value(1).toULongLong() * 1024;
    }
    m_metrics = {{QStringLiteral("available"), totalMemory > 0}, {QStringLiteral("cpuPercent"), qBound(0.0, busy, 100.0)},
        {QStringLiteral("memoryTotal"), static_cast<qint64>(totalMemory)},
        {QStringLiteral("memoryUsed"), static_cast<qint64>(totalMemory - qMin(totalMemory, availableMemory))}};
    m_metricsAge.start();
    return m_metrics;
}
// ---------------------------------------------------------------- desenfoque
// KWin aplica el desenfoque de ext-background-effect-v1 con su efecto Blur;
// su intensidad es [Effect-blur] BlurStrength de kwinrc (1–15, 15 por
// defecto). Se lee el archivo directamente (solo lectura) y se escribe con la
// herramienta oficial kwriteconfig6 con argumentos fijos y un entero acotado;
// después se pide a KWin que recargue el efecto por D-Bus.
int DesktopActions::parseBlurStrength(const QString &kwinrc) {
    bool inGroup = false;
    int value = 0;
    const auto lines = QStringView(kwinrc).split(QLatin1Char('\n'));
    for (const auto raw : lines) {
        const QStringView line = raw.trimmed();
        if (line.startsWith(QLatin1Char('['))) { inGroup = line == QLatin1String("[Effect-blur]"); continue; }
        if (!inGroup || !line.startsWith(QLatin1String("BlurStrength"))) continue;
        const qsizetype equals = line.indexOf(QLatin1Char('='));
        if (equals < 0 || line.left(equals).trimmed() != QLatin1String("BlurStrength")) continue;
        bool ok = false;
        const int parsed = line.mid(equals + 1).trimmed().toInt(&ok);
        value = ok && parsed >= 1 && parsed <= 15 ? parsed : 0;
    }
    return value;
}
Reply DesktopActions::blur() {
    int strength = 0;
    // Mismo orden que KConfig: sistema primero, usuario después (gana el último).
    QStringList files = QStandardPaths::locateAll(QStandardPaths::GenericConfigLocation, QStringLiteral("kwinrc"));
    std::reverse(files.begin(), files.end());
    for (const QString &path : files) {
        QFile file(path);
        if (file.size() > 1024 * 1024 || !file.open(QIODevice::ReadOnly)) continue;
        if (const int found = parseBlurStrength(QString::fromUtf8(file.readAll()))) strength = found;
    }
    return QJsonObject{{QStringLiteral("strength"), strength ? strength : 15},
        {QStringLiteral("writable"), !QStandardPaths::findExecutable(QStringLiteral("kwriteconfig6")).isEmpty()}};
}
Reply DesktopActions::setBlur(const QJsonObject &payload) {
    const QJsonValue value = payload.value(QStringLiteral("strength"));
    if (!value.isDouble() || value.toDouble() != value.toInt(-1) || value.toInt() < 1 || value.toInt() > 15)
        return invalid(QStringLiteral("strength debe ser un entero de 1 a 15"));
    const QString writer = QStandardPaths::findExecutable(QStringLiteral("kwriteconfig6"));
    if (writer.isEmpty()) return protocol::Error{QStringLiteral("unavailable"), QStringLiteral("falta kwriteconfig6 (KConfig 6)"), false};
    if (m_blurBusy) return protocol::Error{QStringLiteral("unavailable"), QStringLiteral("cambio de desenfoque en curso"), true};
    m_blurBusy = true;
    const QString token = QUuid::createUuid().toString(QUuid::WithoutBraces);
    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process, token](int code, QProcess::ExitStatus status) {
        m_blurBusy = false;
        process->deleteLater();
        const bool written = status == QProcess::NormalExit && code == 0;
        if (written) {
            auto message = method(QStringLiteral("org.kde.KWin"), QStringLiteral("/Effects"),
                QStringLiteral("org.kde.kwin.Effects"), QStringLiteral("reconfigureEffect"));
            message << QStringLiteral("blur");
            dispatch(QDBusConnection::sessionBus(), message);
        }
        emit event(QStringLiteral("system.action"), {{QStringLiteral("token"), token}, {QStringLiteral("ok"), written},
            {QStringLiteral("message"), written ? QString() : QStringLiteral("kwriteconfig6 no guardó el valor")}});
    });
    connect(process, &QProcess::errorOccurred, this, [this, process, token](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart) return;
        m_blurBusy = false;
        process->deleteLater();
        emit event(QStringLiteral("system.action"), {{QStringLiteral("token"), token}, {QStringLiteral("ok"), false},
            {QStringLiteral("message"), QStringLiteral("no se pudo ejecutar kwriteconfig6")}});
    });
    process->start(writer, {QStringLiteral("--file"), QStringLiteral("kwinrc"), QStringLiteral("--group"),
        QStringLiteral("Effect-blur"), QStringLiteral("--key"), QStringLiteral("BlurStrength"),
        QStringLiteral("--notify"), QStringLiteral("--"), QString::number(value.toInt())});
    return QJsonObject{{QStringLiteral("accepted"), true}, {QStringLiteral("token"), token}};
}
}
