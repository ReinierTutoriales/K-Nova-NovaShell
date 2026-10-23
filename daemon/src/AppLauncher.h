// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QDBusMessage>
#include <QString>
#include <QStringList>

namespace nova {
// Starts an application as its own transient systemd user unit
// (app-novashell-<id>-<random>.service). The user manager spawns it, so the
// app inherits neither this daemon's sandboxing (NoNewPrivileges blocks sudo,
// pkexec and setuid helpers) nor its cgroup (restarting the daemon must not
// kill the apps it opened). Fixed executables only: never a command line.
class AppLauncher {
public:
    // Unit name per the XDG/systemd convention; id is a validated desktop ID.
    static QString unitName(const QString &desktopId, const QString &random);
    // The StartTransientUnit call (exposed for signature tests).
    static QDBusMessage request(const QString &desktopId, const QString &description, const QStringList &argv);
    // Returns an empty string on success, otherwise the reason it failed.
    // `available` is false when there is no systemd user manager.
    static QString start(const QString &desktopId, const QString &description,
                         const QStringList &argv, bool *available);
};
}
