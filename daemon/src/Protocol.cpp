// SPDX-License-Identifier: GPL-3.0-or-later
#include "Protocol.h"

#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonValue>
#include <QRegularExpression>

namespace nova::protocol {

namespace {

Error makeError(const char *code, const QString &message)
{
    return Error{QString::fromLatin1(code), message, false};
}

QByteArray encode(const QJsonObject &object)
{
    QByteArray line = QJsonDocument(object).toJson(QJsonDocument::Compact);
    line.append('\n');
    return line;
}

} // namespace

bool isValidOperationName(const QString &operation)
{
    // grupo.accion[.subaccion], minúsculas y guiones: "platform.ping".
    static const QRegularExpression pattern(
        QStringLiteral("^[a-z][a-z0-9-]*(\\.[a-z][a-z0-9-]*)+$"));
    return operation.size() <= 96 && pattern.match(operation).hasMatch();
}

ParseResult parseRequest(const QByteArray &line)
{
    ParseResult out;

    if (line.size() > MaxLineBytes) {
        out.error = makeError(code::RequestTooLarge,
            QStringLiteral("la petición supera %1 bytes").arg(MaxLineBytes));
        return out;
    }

    QJsonParseError parseError{};
    const QJsonDocument document = QJsonDocument::fromJson(line, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        out.error = makeError(code::InvalidJson,
            QStringLiteral("se esperaba un objeto JSON"));
        return out;
    }
    const QJsonObject object = document.object();

    const QJsonValue idValue = object.value(QLatin1String("requestId"));
    if (idValue.isString() && !idValue.toString().isEmpty()
        && idValue.toString().size() <= MaxRequestIdLength) {
        out.requestId = idValue.toString();
    } else {
        out.error = makeError(code::InvalidRequest,
            QStringLiteral("requestId debe ser un texto de 1 a %1 caracteres")
                .arg(MaxRequestIdLength));
        return out;
    }

    const QJsonValue versionValue = object.value(QLatin1String("version"));
    if (!versionValue.isDouble() || versionValue.toDouble() != static_cast<double>(Version)) {
        out.error = makeError(code::UnsupportedVersion,
            QStringLiteral("versión de protocolo soportada: %1").arg(Version));
        return out;
    }

    const QJsonValue operationValue = object.value(QLatin1String("operation"));
    if (!operationValue.isString() || !isValidOperationName(operationValue.toString())) {
        out.error = makeError(code::InvalidRequest,
            QStringLiteral("operation inválida"));
        return out;
    }

    const QJsonValue payloadValue = object.value(QLatin1String("payload"));
    if (!payloadValue.isUndefined() && !payloadValue.isNull() && !payloadValue.isObject()) {
        out.error = makeError(code::InvalidRequest,
            QStringLiteral("payload debe ser un objeto"));
        return out;
    }

    out.request = Request{out.requestId, operationValue.toString(), payloadValue.toObject()};
    return out;
}

QByteArray encodeResult(const QString &requestId, const QJsonObject &result)
{
    return encode(QJsonObject{
        {QStringLiteral("version"), Version},
        {QStringLiteral("requestId"), requestId},
        {QStringLiteral("ok"), true},
        {QStringLiteral("result"), result},
    });
}

QByteArray encodeError(const QString &requestId, const Error &error)
{
    return encode(QJsonObject{
        {QStringLiteral("version"), Version},
        {QStringLiteral("requestId"), requestId.isEmpty() ? QJsonValue() : QJsonValue(requestId)},
        {QStringLiteral("ok"), false},
        {QStringLiteral("error"), QJsonObject{
            {QStringLiteral("code"), error.code},
            {QStringLiteral("message"), error.message},
            {QStringLiteral("retryable"), error.retryable},
        }},
    });
}

QByteArray encodeEvent(const QString &event, const QJsonObject &payload)
{
    return encode(QJsonObject{
        {QStringLiteral("version"), Version},
        {QStringLiteral("event"), event},
        {QStringLiteral("payload"), payload},
    });
}

} // namespace nova::protocol
