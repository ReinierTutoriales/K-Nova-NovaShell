// SPDX-License-Identifier: GPL-3.0-or-later
#include "Protocol.h"
#include "Router.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QTest>

using namespace nova;
using namespace nova::protocol;

class TestProtocol : public QObject
{
    Q_OBJECT

private:
    static QJsonObject decode(const QByteArray &line)
    {
        return QJsonDocument::fromJson(line).object();
    }

private slots:
    void validRequest()
    {
        const auto r = parseRequest(R"({"version":1,"requestId":"7","operation":"platform.ping"})");
        QVERIFY(!r.error);
        QVERIFY(r.request);
        QCOMPARE(r.request->requestId, QStringLiteral("7"));
        QCOMPARE(r.request->operation, QStringLiteral("platform.ping"));
        QVERIFY(r.request->payload.isEmpty());
    }

    void rejectsInvalidJson()
    {
        const auto r = parseRequest("{no es json");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::InvalidJson));
    }

    void rejectsNonObject()
    {
        const auto r = parseRequest("[1,2,3]");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::InvalidJson));
    }

    void rejectsMissingRequestId()
    {
        const auto r = parseRequest(R"({"version":1,"operation":"platform.ping"})");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::InvalidRequest));
        QVERIFY(r.requestId.isEmpty());
    }

    void rejectsLongRequestId()
    {
        const QByteArray id(MaxRequestIdLength + 1, 'a');
        const auto r = parseRequest(R"({"version":1,"requestId":")" + id
            + R"(","operation":"platform.ping"})");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::InvalidRequest));
    }

    void rejectsWrongVersionButKeepsId()
    {
        const auto r = parseRequest(R"({"version":2,"requestId":"9","operation":"platform.ping"})");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::UnsupportedVersion));
        QCOMPARE(r.requestId, QStringLiteral("9"));
    }

    void rejectsBadOperationNames_data()
    {
        QTest::addColumn<QString>("operation");
        QTest::newRow("sin grupo") << QStringLiteral("ping");
        QTest::newRow("mayúsculas") << QStringLiteral("Platform.Ping");
        QTest::newRow("espacios") << QStringLiteral("platform. ping");
        QTest::newRow("inyección") << QStringLiteral("platform.ping;rm");
        QTest::newRow("vacía") << QString();
    }

    void rejectsBadOperationNames()
    {
        QFETCH(QString, operation);
        QVERIFY(!isValidOperationName(operation));
    }

    void rejectsNonObjectPayload()
    {
        const auto r = parseRequest(
            R"({"version":1,"requestId":"1","operation":"platform.ping","payload":[1]})");
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::InvalidRequest));
    }

    void rejectsOversizedLine()
    {
        const QByteArray big(MaxLineBytes + 1, ' ');
        const auto r = parseRequest(big);
        QVERIFY(r.error);
        QCOMPARE(r.error->code, QString::fromLatin1(code::RequestTooLarge));
    }

    void encodesSingleLine()
    {
        const QByteArray line = encodeResult(QStringLiteral("3"), {{QStringLiteral("a"), 1}});
        QVERIFY(line.endsWith('\n'));
        QCOMPARE(line.count('\n'), 1);
        const QJsonObject o = decode(line);
        QCOMPARE(o.value(QStringLiteral("ok")).toBool(), true);
        QCOMPARE(o.value(QStringLiteral("requestId")).toString(), QStringLiteral("3"));
        QCOMPARE(o.value(QStringLiteral("version")).toInt(), Version);
    }

    void errorWithoutIdIsNull()
    {
        const QJsonObject o = decode(encodeError(QString(), {QStringLiteral("x"), QStringLiteral("y"), false}));
        QVERIFY(o.value(QStringLiteral("requestId")).isNull());
        QCOMPARE(o.value(QStringLiteral("ok")).toBool(), false);
    }

    void routerDispatchesAndListsCapabilities()
    {
        const Router router = Router::makeDefault();
        const Reply ping = router.dispatch({QStringLiteral("1"), QStringLiteral("platform.ping"), {}});
        QVERIFY(std::holds_alternative<QJsonObject>(ping));
        QCOMPARE(std::get<QJsonObject>(ping).value(QStringLiteral("ready")).toBool(), true);

        const Reply caps = router.dispatch({QStringLiteral("2"), QStringLiteral("platform.capabilities"), {}});
        const QJsonArray ops = std::get<QJsonObject>(caps).value(QStringLiteral("operations")).toArray();
        QVERIFY(ops.contains(QStringLiteral("platform.ping")));
        QVERIFY(ops.contains(QStringLiteral("platform.capabilities")));
    }

    void routerRejectsUnknownAndDuplicates()
    {
        Router router = Router::makeDefault();
        const Reply r = router.dispatch({QStringLiteral("1"), QStringLiteral("system.reboot"), {}});
        QVERIFY(std::holds_alternative<Error>(r));
        QCOMPARE(std::get<Error>(r).code, QString::fromLatin1(code::UnknownOperation));
        QVERIFY(!router.add(QStringLiteral("platform.ping"), [](const QJsonObject &) -> Reply { return QJsonObject{}; }));
        QVERIFY(!router.add(QStringLiteral("platform.capabilities"), [](const QJsonObject &) -> Reply { return QJsonObject{}; }));
    }

    void routerContainsThrowingHandler()
    {
        Router router;
        router.add(QStringLiteral("test.boom"), [](const QJsonObject &) -> Reply {
            throw std::runtime_error("fallo");
        });
        const Reply r = router.dispatch({QStringLiteral("1"), QStringLiteral("test.boom"), {}});
        QVERIFY(std::holds_alternative<Error>(r));
        QCOMPARE(std::get<Error>(r).code, QString::fromLatin1(code::Internal));
    }
};

QTEST_GUILESS_MAIN(TestProtocol)
#include "tst_protocol.moc"
