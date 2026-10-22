// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "Router.h"

#include <QByteArray>
#include <QHash>
#include <QLocalServer>
#include <QObject>
#include <QString>

class QLocalSocket;

namespace nova {

// Servidor JSONL sobre un socket Unix por usuario.
// Seguridad: directorio 0700 (lo crea main), socket 0600 y verificación
// SO_PEERCRED de que el cliente es el mismo UID que el daemon.
class Server : public QObject
{
    Q_OBJECT
public:
    static constexpr int MaxClients = 32;

    explicit Server(Router router, QObject *parent = nullptr);
    ~Server() override;

    bool listen(const QString &socketPath, QString *errorMessage);
    QString socketPath() const { return m_socketPath; }

private:
    void acceptConnections();
    void readClient(QLocalSocket *socket);
    void handleLine(QLocalSocket *socket, const QByteArray &line);
    void dropClient(QLocalSocket *socket);

    QLocalServer m_server;
    Router m_router;
    QString m_socketPath;
    QHash<QLocalSocket *, QByteArray> m_buffers;
};

} // namespace nova
