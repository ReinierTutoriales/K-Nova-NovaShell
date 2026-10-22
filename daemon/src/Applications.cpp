// SPDX-License-Identifier: GPL-3.0-or-later
// Include GIO before Qt's signals macro.
#include <gio/gdesktopappinfo.h>
#include "Applications.h"
#include <QDir>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QStandardPaths>
#include <algorithm>

namespace nova {
namespace {
QString text(const char *value, qsizetype limit) {
    return value ? QString::fromUtf8(value).left(limit) : QString();
}
protocol::Error invalid(const QString &message) {
    return {QString::fromLatin1(protocol::code::InvalidRequest), message, false};
}
}
bool Applications::validId(const QString &id) {
    static const QRegularExpression control(QStringLiteral("[\\x00-\\x1f\\x7f/\\\\]"));
    return id.endsWith(QLatin1String(".desktop")) && id.size() <= 255
        && id.size() > 8 && !id.startsWith(QLatin1Char('.')) && !control.match(id).hasMatch();
}
Applications::Applications() {
    for (const auto &directory : QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation)) {
        if (QDir(directory).exists()) m_watcher.addPath(directory);
    }
    QObject::connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_watcher,
                     [this] { m_age.invalidate(); });
}
void Applications::refresh() {
    if (m_age.isValid() && m_age.elapsed() < 30000) return;
    QList<QJsonObject> records;
    GList *applications = g_app_info_get_all();
    for (GList *entry = applications; entry; entry = entry->next) {
        auto *app = G_APP_INFO(entry->data);
        const QString id = text(g_app_info_get_id(app), 256);
        if (!validId(id) || !g_app_info_should_show(app)) continue;
        QString icon;
        if (GIcon *value = g_app_info_get_icon(app)) {
            if (G_IS_THEMED_ICON(value)) {
                const char *const *names = g_themed_icon_get_names(G_THEMED_ICON(value));
                if (names && *names) icon = text(*names, 512);
            } else if (G_IS_FILE_ICON(value)) {
                char *path = g_file_get_path(g_file_icon_get_file(G_FILE_ICON(value)));
                icon = text(path, 2048);
                g_free(path);
            }
        }
        QString keywords;
        if (G_IS_DESKTOP_APP_INFO(app)) {
            const char *const *words = g_desktop_app_info_get_keywords(G_DESKTOP_APP_INFO(app));
            if (words) for (int i = 0; words[i] && i < 12; ++i) keywords += text(words[i], 48) + QLatin1Char(' ');
        }
        records.append({{QStringLiteral("id"), id},
            {QStringLiteral("name"), text(g_app_info_get_display_name(app), 128)},
            {QStringLiteral("icon"), icon}, {QStringLiteral("keywords"), keywords.left(256)}});
    }
    g_list_free_full(applications, g_object_unref);
    std::sort(records.begin(), records.end(), [](const auto &a, const auto &b) {
        return QString::localeAwareCompare(a.value(QStringLiteral("name")).toString(),
                                            b.value(QStringLiteral("name")).toString()) < 0;
    });
    m_entries = QJsonArray();
    for (const auto &entry : records) m_entries.append(entry);
    m_age.start();
}
Reply Applications::list(const QJsonObject &payload) {
    const int offset = payload.value(QStringLiteral("offset")).toInt(0);
    const int limit = payload.value(QStringLiteral("limit")).toInt(24);
    if (offset < 0 || offset > 100000 || limit < 1 || limit > 32)
        return invalid(QStringLiteral("offset o limit fuera de rango"));
    refresh();
    QJsonArray page;
    // Keep each response bounded even with unusually large desktop metadata.
    qsizetype bytes = 0;
    int next = offset;
    while (next < m_entries.size() && page.size() < limit) {
        const auto entry = m_entries.at(next).toObject();
        const qsizetype size = QJsonDocument(entry).toJson(QJsonDocument::Compact).size();
        if (!page.isEmpty() && bytes + size > 48000) break;
        page.append(entry);
        bytes += size;
        ++next;
    }
    return QJsonObject{{QStringLiteral("applications"), page}, {QStringLiteral("next"), next},
        {QStringLiteral("total"), static_cast<qint64>(m_entries.size())}};
}
Reply Applications::launch(const QJsonObject &payload) {
    const QString id = payload.value(QStringLiteral("id")).toString();
    if (!validId(id)) return invalid(QStringLiteral("identificador de aplicación inválido"));
    GDesktopAppInfo *app = g_desktop_app_info_new(id.toUtf8().constData());
    if (!app) return invalid(QStringLiteral("aplicación no instalada"));
    GError *error = nullptr;
    const bool launched = g_app_info_launch(G_APP_INFO(app), nullptr, nullptr, &error);
    g_object_unref(app);
    if (!launched) {
        const QString message = error ? QString::fromUtf8(error->message) : QStringLiteral("no se pudo iniciar");
        g_clear_error(&error);
        return protocol::Error{QStringLiteral("launch-failed"), message.left(512), false};
    }
    return QJsonObject{{QStringLiteral("launched"), true}, {QStringLiteral("id"), id}};
}
}
