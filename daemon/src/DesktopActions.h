// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "Router.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QElapsedTimer>
#include <QObject>

namespace nova {
class DesktopActions : public QObject {
    Q_OBJECT
public:
    Reply session(const QJsonObject &payload);
    Reply screenshot();
    Reply wallpaper(const QJsonObject &payload);
    Reply brightness();
    Reply setBrightness(const QJsonObject &payload);
    Reply metrics();
signals:
    void event(const QString &name, const QJsonObject &payload);
private:
    Reply dispatch(const QDBusConnection &bus, const QDBusMessage &message);
    void finishBrightness();
    int m_pending = 0;
    bool m_brightnessBusy = false;
    QJsonObject m_brightness;
    QHash<QString, QJsonObject> m_displays;
    QElapsedTimer m_brightnessAge;
    QElapsedTimer m_metricsAge;
    QJsonObject m_metrics;
    quint64 m_cpuTotal = 0;
    quint64 m_cpuIdle = 0;
};
}
