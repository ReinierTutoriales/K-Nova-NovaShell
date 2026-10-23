// SPDX-License-Identifier: GPL-3.0-or-later
#include "AppLauncher.h"
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusVariant>
#include <QUuid>

namespace {
struct ExecCommand {
    QString path;
    QStringList argv;
    bool ignoreFailure = false;
};
struct UnitProperty {
    QString name;
    QDBusVariant value;
};
struct AuxUnit {
    QString name;
    QList<UnitProperty> properties;
};
QDBusArgument &operator<<(QDBusArgument &out, const ExecCommand &command) {
    out.beginStructure();
    out << command.path << command.argv << command.ignoreFailure;
    out.endStructure();
    return out;
}
const QDBusArgument &operator>>(const QDBusArgument &in, ExecCommand &command) {
    in.beginStructure();
    in >> command.path >> command.argv >> command.ignoreFailure;
    in.endStructure();
    return in;
}
QDBusArgument &operator<<(QDBusArgument &out, const UnitProperty &property) {
    out.beginStructure();
    out << property.name << property.value;
    out.endStructure();
    return out;
}
const QDBusArgument &operator>>(const QDBusArgument &in, UnitProperty &property) {
    in.beginStructure();
    in >> property.name >> property.value;
    in.endStructure();
    return in;
}
QDBusArgument &operator<<(QDBusArgument &out, const AuxUnit &unit) {
    out.beginStructure();
    out << unit.name << unit.properties;
    out.endStructure();
    return out;
}
const QDBusArgument &operator>>(const QDBusArgument &in, AuxUnit &unit) {
    in.beginStructure();
    in >> unit.name >> unit.properties;
    in.endStructure();
    return in;
}
}
Q_DECLARE_METATYPE(ExecCommand)
Q_DECLARE_METATYPE(UnitProperty)
Q_DECLARE_METATYPE(AuxUnit)

namespace nova {
namespace {
void registerTypes() {
    static const bool done = [] {
        qDBusRegisterMetaType<ExecCommand>();
        qDBusRegisterMetaType<QList<ExecCommand>>();
        qDBusRegisterMetaType<UnitProperty>();
        qDBusRegisterMetaType<QList<UnitProperty>>();
        qDBusRegisterMetaType<AuxUnit>();
        qDBusRegisterMetaType<QList<AuxUnit>>();
        return true;
    }();
    Q_UNUSED(done);
}
UnitProperty property(const QString &name, const QVariant &value) {
    return {name, QDBusVariant(value)};
}
}
QString AppLauncher::unitName(const QString &desktopId, const QString &random) {
    // systemd unit names allow [A-Za-z0-9:_.\\-]; '-' separates fields, so
    // anything else (and '-') inside the ID is escaped like systemd-escape.
    QString id = desktopId.endsWith(QLatin1String(".desktop")) ? desktopId.chopped(8) : desktopId;
    QString escaped;
    for (const QChar c : id) {
        const ushort u = c.unicode();
        const bool plain = (u >= 'a' && u <= 'z') || (u >= 'A' && u <= 'Z') || (u >= '0' && u <= '9')
            || u == '_' || u == '.' || u == ':';
        if (plain) {
            escaped += c;
        } else {
            for (const char byte : QString(c).toUtf8())
                escaped += QStringLiteral("\\x%1").arg(static_cast<uchar>(byte), 2, 16, QLatin1Char('0'));
        }
    }
    // Unit names are limited to 255 bytes including the suffix.
    return QStringLiteral("app-novashell-%1-%2.service").arg(escaped.left(200), random);
}
QDBusMessage AppLauncher::request(const QString &desktopId, const QString &description, const QStringList &argv) {
    registerTypes();
    const QString random = QUuid::createUuid().toString(QUuid::Id128).left(12);
    const QList<ExecCommand> exec{{argv.value(0), argv, false}};
    // ExitType=cgroup keeps the unit while the app runs even if the launcher
    // process (gio launch) exits first; the unit is collected afterwards.
    const QList<UnitProperty> properties{
        property(QStringLiteral("Description"), description.left(128)),
        property(QStringLiteral("ExecStart"), QVariant::fromValue(exec)),
        property(QStringLiteral("Type"), QStringLiteral("exec")),
        property(QStringLiteral("ExitType"), QStringLiteral("cgroup")),
        property(QStringLiteral("CollectMode"), QStringLiteral("inactive-or-failed")),
        property(QStringLiteral("Slice"), QStringLiteral("app.slice")),
    };
    auto message = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.systemd1"),
        QStringLiteral("/org/freedesktop/systemd1"), QStringLiteral("org.freedesktop.systemd1.Manager"),
        QStringLiteral("StartTransientUnit"));
    message << unitName(desktopId, random) << QStringLiteral("fail")
            << QVariant::fromValue(properties) << QVariant::fromValue(QList<AuxUnit>{});
    return message;
}
QString AppLauncher::start(const QString &desktopId, const QString &description,
                           const QStringList &argv, bool *available) {
    QDBusConnection bus = QDBusConnection::sessionBus();
    *available = bus.isConnected() && bus.interface()
        && bus.interface()->isServiceRegistered(QStringLiteral("org.freedesktop.systemd1"));
    if (!*available || argv.isEmpty()) return QStringLiteral("sin gestor de usuario systemd");
    // Short and bounded: the user manager answers immediately (job queued).
    const QDBusMessage reply = bus.call(request(desktopId, description, argv), QDBus::Block, 3000);
    return reply.type() == QDBusMessage::ErrorMessage ? reply.errorMessage().left(512) : QString();
}
}
