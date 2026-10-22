// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "Router.h"
#include <QElapsedTimer>
#include <QFileSystemWatcher>
#include <QJsonArray>

namespace nova {
class Applications {
public:
    Applications();
    Reply list(const QJsonObject &payload);
    Reply launch(const QJsonObject &payload);
    static bool validId(const QString &id);
private:
    void refresh();
    QJsonArray m_entries;
    QElapsedTimer m_age;
    QFileSystemWatcher m_watcher;
};
}
