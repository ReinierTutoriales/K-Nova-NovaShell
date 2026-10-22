// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QString>

#include <optional>

// Protocolo IPC v1 de NovaShell: objetos JSON UTF-8 separados por '\n'.
// Ver docs/CONTRATO-IPC-v1.md. Este módulo no conoce sockets.
namespace nova::protocol {

inline constexpr int Version = 1;
// Una línea mayor que esto se rechaza y la conexión se cierra.
inline constexpr qsizetype MaxLineBytes = 64 * 1024;
inline constexpr qsizetype MaxRequestIdLength = 64;

namespace code {
inline constexpr auto InvalidJson = "invalid-json";
inline constexpr auto InvalidRequest = "invalid-request";
inline constexpr auto UnsupportedVersion = "unsupported-version";
inline constexpr auto UnknownOperation = "unknown-operation";
inline constexpr auto RequestTooLarge = "request-too-large";
inline constexpr auto Internal = "internal";
} // namespace code

struct Error {
    QString code;
    QString message;
    bool retryable = false;
};

struct Request {
    QString requestId;
    QString operation;
    QJsonObject payload;
};

struct ParseResult {
    std::optional<Request> request;
    std::optional<Error> error;
    // requestId recuperado aunque la petición sea inválida, para poder
    // responder el error al llamador correcto. Vacío si no se pudo leer.
    QString requestId;
};

ParseResult parseRequest(const QByteArray &line);

bool isValidOperationName(const QString &operation);

QByteArray encodeResult(const QString &requestId, const QJsonObject &result);
QByteArray encodeError(const QString &requestId, const Error &error);
QByteArray encodeEvent(const QString &event, const QJsonObject &payload);

} // namespace nova::protocol
