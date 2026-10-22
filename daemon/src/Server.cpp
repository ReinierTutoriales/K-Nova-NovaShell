// SPDX-License-Identifier: GPL-3.0-or-later
#include "Server.h"

#include <QFile>
#include <QLocalSocket>
#include <QLoggingCategory>

#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

Q_LOGGING_CATEGORY(lcServer, "nova.platform.server")

namespace nova {

namespace {

bool peerIsSameUser(QLocalSocket *socket)
{
    struct ucred credentials{};
    socklen_t length = sizeof(credentials);
    const auto fd = static_cast<int>(socket->socketDescriptor());
    if (fd < 0 || getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &credentials, &length) != 0) {
        return false;
    }
    return credentials.uid == getuid();
}

} // namespace

Server::Server(Router router, QObject *parent)
    : QObject(parent)
    , m_router(std::move(router))
{
    m_server.setSocketOptions(QLocalServer::UserAccessOption);
    m_server.setMaxPendingConnections(MaxClients);
    connect(&m_server, &QLocalServer::newConnection, this, &Server::acceptConnections);
}

Server::~Server()
{
    m_server.close();
    if (!m_socketPath.isEmpty()) {
        QLocalServer::removeServer(m_socketPath);
    }
}

bool Server::listen(const QString &socketPath, QString *errorMessage)
{
    // ¿Ya hay un daemon vivo? Entonces no le robamos el socket.
    {
        QLocalSocket probe;
        probe.connectToServer(socketPath);
        if (probe.waitForConnected(200)) {
            *errorMessage = QStringLiteral("ya hay un nova-platform escuchando en %1").arg(socketPath);
            return false;
        }
    }

    QLocalServer::removeServer(socketPath); // socket huérfano de un cierre abrupto
    if (!m_server.listen(socketPath)) {
        *errorMessage = m_server.errorString();
        return false;
    }
    // Refuerzo explícito: no depender del umask ni de la opción anterior.
    QFile::setPermissions(socketPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    m_socketPath = socketPath;
    qCInfo(lcServer) << "escuchando en" << socketPath;
    return true;
}

void Server::acceptConnections()
{
    while (m_server.hasPendingConnections()) {
        QLocalSocket *socket = m_server.nextPendingConnection();
        if (!socket) {
            continue;
        }
        if (m_buffers.size() >= MaxClients || !peerIsSameUser(socket)) {
            qCWarning(lcServer) << "conexión rechazada (límite o UID distinto)";
            socket->disconnectFromServer();
            socket->deleteLater();
            continue;
        }
        socket->setReadBufferSize(protocol::MaxLineBytes + 1);
        m_buffers.insert(socket, QByteArray());
        connect(socket, &QLocalSocket::readyRead, this, [this, socket] { readClient(socket); });
        connect(socket, &QLocalSocket::disconnected, this, [this, socket] { dropClient(socket); });
        if (socket->bytesAvailable() > 0) {
            readClient(socket);
        }
    }
}

void Server::readClient(QLocalSocket *socket)
{
    auto it = m_buffers.find(socket);
    if (it == m_buffers.end()) {
        return;
    }
    while (socket->bytesAvailable() > 0) {
        const qint64 capacity = protocol::MaxLineBytes + 1 - it->size();
        // QIODevice reserves one byte for the terminating NUL.
        const QByteArray chunk = socket->readLine(capacity + 1);
        if (chunk.isEmpty()) {
            break;
        }
        it->append(chunk);
        const bool complete = it->endsWith('\n');
        const qsizetype payloadSize = it->size() - (complete ? 1 : 0);
        // Check raw bytes before trimming: padding counts toward the limit.
        if (payloadSize > protocol::MaxLineBytes) {
            socket->write(protocol::encodeError(QString(),
                {QString::fromLatin1(protocol::code::RequestTooLarge),
                 QStringLiteral("línea demasiado larga; conexión cerrada"), false}));
            socket->flush();
            m_buffers.remove(socket);
            socket->disconnectFromServer();
            socket->deleteLater();
            return;
        }
        if (complete) {
            const QByteArray line = it->trimmed();
            it->clear();
            if (!line.isEmpty()) {
                handleLine(socket, line);
            }
            it = m_buffers.find(socket);
            if (it == m_buffers.end()) {
                return;
            }
        }
    }
}

void Server::handleLine(QLocalSocket *socket, const QByteArray &line)
{
    const protocol::ParseResult parsed = protocol::parseRequest(line);
    if (parsed.error) {
        socket->write(protocol::encodeError(parsed.requestId, *parsed.error));
        return;
    }

    const Reply reply = m_router.dispatch(*parsed.request);
    if (const auto *result = std::get_if<QJsonObject>(&reply)) {
        socket->write(protocol::encodeResult(parsed.requestId, *result));
    } else {
        socket->write(protocol::encodeError(parsed.requestId, std::get<protocol::Error>(reply)));
    }
}

void Server::dropClient(QLocalSocket *socket)
{
    if (m_buffers.remove(socket) > 0) {
        socket->deleteLater();
    }
}

} // namespace nova
