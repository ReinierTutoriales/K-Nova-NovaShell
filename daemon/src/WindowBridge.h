// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "Router.h"
#include <QDBusContext>
#include <QDBusMessage>
#include <QDBusServiceWatcher>
#include <QJsonArray>
#include <QTimer>

namespace nova {
class WindowBridge : public QObject, protected QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.nova.Shell.Windows")
public:
    WindowBridge();
    ~WindowBridge() override;
    Reply snapshot() const;
    Reply action(const QJsonObject &payload);
signals:
    void changed(const QJsonObject &snapshot);
    void shortcutRequested(const QString &panel);
public slots:
    Q_SCRIPTABLE void Publish(const QString &payload);
    Q_SCRIPTABLE QString TakeCommand();
    Q_SCRIPTABLE void Shortcut(const QString &panel);
private:
    void load();
    bool authorized() const;
    void release(const QString &command = {});
    bool m_registered = false;
    QString m_owner;
    QJsonObject m_snapshot;
    QDBusMessage m_waiter;
    bool m_waiting = false;
    QTimer m_heartbeat;
    QDBusServiceWatcher m_watcher;
};
}
