// SPDX-License-Identifier: GPL-3.0-or-later
#include "Preferences.h"
#include "Applications.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QStandardPaths>
#include <QSet>
#include <cmath>

namespace nova {
QJsonObject Preferences::defaults() {
    static const QJsonObject values{{QStringLiteral("mode"), QStringLiteral("auto")},
        {QStringLiteral("material"), QStringLiteral("frosted")},
        {QStringLiteral("iconMode"), QStringLiteral("default")},
        {QStringLiteral("transparency"), 0.5}, {QStringLiteral("dockIconSize"), 56},
        {QStringLiteral("dockAutoHide"), false}, {QStringLiteral("dockMagnify"), false},
        {QStringLiteral("doNotDisturb"), false}, {QStringLiteral("showSeconds"), false},
        {QStringLiteral("desktopWidgets"), true},
        {QStringLiteral("notificationServer"), false}, {QStringLiteral("clipboardEnabled"), false},
        {QStringLiteral("reduceMotion"), false}, {QStringLiteral("reduceTransparency"), false},
        {QStringLiteral("highContrast"), false}, {QStringLiteral("backgroundBlur"), true},
        {QStringLiteral("pins"), QJsonArray{QStringLiteral("org.kde.dolphin.desktop"),
            QStringLiteral("org.kde.konsole.desktop"), QStringLiteral("firefox.desktop"),
            QStringLiteral("systemsettings.desktop")}}};
    return values;
}
bool Preferences::valid(const QString &key, const QJsonValue &value) {
    if (!defaults().contains(key)) return false;
    if (key == QLatin1String("mode")) return QStringList{"auto", "light", "dark"}.contains(value.toString());
    if (key == QLatin1String("material")) return QStringList{"liquid", "frosted", "solid"}.contains(value.toString());
    if (key == QLatin1String("iconMode")) return QStringList{"default", "dark", "clear", "tinted"}.contains(value.toString());
    if (key == QLatin1String("transparency")) return value.isDouble() && value.toDouble() >= 0 && value.toDouble() <= 1;
    if (key == QLatin1String("dockIconSize")) return value.isDouble() && value.toDouble() == value.toInt(-1)
        && value.toInt() >= 36 && value.toInt() <= 80;
    if (key == QLatin1String("pins")) {
        if (!value.isArray() || value.toArray().size() > 24) return false;
        QSet<QString> seen;
        for (const auto &entry : value.toArray()) {
            const QString id = entry.toString();
            if (!entry.isString() || !Applications::validId(id) || seen.contains(id)) return false;
            seen.insert(id);
        }
        return true;
    }
    return value.isBool();
}
Preferences::Preferences(QString path) : m_path(std::move(path)), m_values(defaults()) {
    if (m_path.isEmpty()) m_path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/novashell/settings.json");
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly) || file.size() > 65536) return;
    const QJsonObject stored = QJsonDocument::fromJson(file.readAll()).object();
    for (auto it = stored.begin(); it != stored.end(); ++it)
        if (valid(it.key(), it.value())) m_values.insert(it.key(), it.value());
}
Reply Preferences::read() const { return QJsonObject{{QStringLiteral("values"), m_values}}; }
Reply Preferences::patch(const QJsonObject &payload) {
    if (payload.isEmpty()) return read();
    QJsonObject next = m_values;
    for (auto it = payload.begin(); it != payload.end(); ++it) {
        if (!valid(it.key(), it.value())) return protocol::Error{QStringLiteral("invalid-request"),
            QStringLiteral("preferencia inválida: %1").arg(it.key()), false};
        next.insert(it.key(), it.value());
    }
    if (!QDir().mkpath(QFileInfo(m_path).absolutePath()))
        return protocol::Error{QStringLiteral("write-failed"), QStringLiteral("no se pudo crear el directorio"), true};
    QSaveFile file(m_path);
    const QByteArray bytes = QJsonDocument(next).toJson(QJsonDocument::Compact);
    if (!file.open(QIODevice::WriteOnly) || !file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner)
        || file.write(bytes) != bytes.size() || !file.commit())
        return protocol::Error{QStringLiteral("write-failed"), QStringLiteral("no se pudieron guardar las preferencias"), true};
    m_values = next;
    return read();
}
}
