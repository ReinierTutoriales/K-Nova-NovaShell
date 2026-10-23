// SPDX-License-Identifier: GPL-3.0-or-later
#include "AppLauncher.h"
#include <QDBusMessage>
#include <QDBusMetaType>
#include "Applications.h"
#include "DesktopActions.h"
#include "Preferences.h"
#include <QFile>
#include <QJsonArray>
#include <QTemporaryDir>
#include <QTest>

using namespace nova;
class TestDesktop : public QObject {
    Q_OBJECT
private slots:
    void desktopActionsRejectUntrustedArguments() {
        DesktopActions actions;
        QVERIFY(std::holds_alternative<protocol::Error>(actions.session({{QStringLiteral("action"), QStringLiteral("sh -c reboot")}})));
        QVERIFY(std::holds_alternative<protocol::Error>(actions.wallpaper({{QStringLiteral("url"), QStringLiteral("https://example.org/image.png")}, {QStringLiteral("screen"), 0}})));
        QVERIFY(std::holds_alternative<protocol::Error>(actions.setBrightness({{QStringLiteral("id"), QStringLiteral("../display")}, {QStringLiteral("percent"), 50}})));
        const auto metrics = std::get<QJsonObject>(actions.metrics());
        QVERIFY(metrics.value(QStringLiteral("available")).toBool());
        QVERIFY(metrics.value(QStringLiteral("memoryTotal")).toDouble() > 0);
        QVERIFY(metrics.value(QStringLiteral("memoryUsed")).toDouble() <= metrics.value(QStringLiteral("memoryTotal")).toDouble());
        QCOMPARE(std::get<QJsonObject>(actions.metrics()), metrics);
    }
    void desktopIdentifiersAreBounded() {
        QVERIFY(Applications::validId(QStringLiteral("org.kde.dolphin.desktop")));
        for (const auto &id : {QStringLiteral("../fake.desktop"), QStringLiteral("/tmp/fake.desktop"),
                              QStringLiteral("fake\n.desktop"), QStringLiteral("command"), QStringLiteral(".desktop")})
            QVERIFY(!Applications::validId(id));
        QVERIFY(!Applications::validId(QString(256, QLatin1Char('a')) + QStringLiteral(".desktop")));
    }
    void launchedAppsGetTheirOwnUnitName() {
        QCOMPARE(AppLauncher::unitName(QStringLiteral("org.kde.konsole.desktop"), QStringLiteral("abc123")),
                 QStringLiteral("app-novashell-org.kde.konsole-abc123.service"));
        // '-' separates fields and other bytes are escaped like systemd-escape.
        QCOMPARE(AppLauncher::unitName(QStringLiteral("my-app ñ.desktop"), QStringLiteral("r")),
                 QStringLiteral("app-novashell-my\\x2dapp\\x20\\xc3\\xb1-r.service"));
        const QString longName = AppLauncher::unitName(QString(250, QLatin1Char('a')) + QStringLiteral(".desktop"),
                                                       QStringLiteral("0123456789ab"));
        QVERIFY(longName.toUtf8().size() <= 255);
        const QDBusMessage request = AppLauncher::request(QStringLiteral("org.kde.konsole.desktop"), QStringLiteral("Konsole"),
            {QStringLiteral("/usr/bin/gio"), QStringLiteral("launch"), QStringLiteral("/usr/share/applications/org.kde.konsole.desktop")});
        QCOMPARE(request.member(), QStringLiteral("StartTransientUnit"));
        // Signature systemd expects: StartTransientUnit(s name, s mode, a(sv), a(sa(sv))).
        QCOMPARE(request.arguments().size(), 4);
        QCOMPARE(QByteArray(QDBusMetaType::typeToSignature(request.arguments().at(2).metaType())), QByteArray("a(sv)"));
        QCOMPARE(QByteArray(QDBusMetaType::typeToSignature(request.arguments().at(3).metaType())), QByteArray("a(sa(sv))"));
        QVERIFY(request.arguments().at(0).toString().startsWith(QStringLiteral("app-novashell-org.kde.konsole-")));
    }
    void preferencesPersistAndRejectPartialUpdates() {
        QTemporaryDir directory;
        const QString path = directory.filePath(QStringLiteral("prefs/settings.json"));
        Preferences first(path);
        QVERIFY(std::holds_alternative<QJsonObject>(first.patch({{QStringLiteral("dockAutoHide"), true}, {QStringLiteral("mode"), QStringLiteral("dark")}})));
        Preferences second(path);
        auto values = std::get<QJsonObject>(second.read()).value(QStringLiteral("values")).toObject();
        QCOMPARE(values.value(QStringLiteral("mode")).toString(), QStringLiteral("dark"));
        QVERIFY(values.value(QStringLiteral("dockAutoHide")).toBool());
        QVERIFY(std::holds_alternative<protocol::Error>(second.patch({{QStringLiteral("mode"), QStringLiteral("light")}, {QStringLiteral("unknown"), true}})));
        QCOMPARE(std::get<QJsonObject>(second.read()).value(QStringLiteral("values")).toObject(), values);
        QVERIFY(std::holds_alternative<protocol::Error>(second.patch({{QStringLiteral("dockIconSize"), 56.5}})));
        QVERIFY(std::holds_alternative<protocol::Error>(second.patch({{QStringLiteral("pins"), QJsonArray{"../bad.desktop"}}})));
        QVERIFY(std::holds_alternative<protocol::Error>(second.patch({{QStringLiteral("pins"), QJsonArray{"same.desktop", "same.desktop"}}})));
        QVERIFY(!(QFile::permissions(path) & (QFileDevice::ReadGroup | QFileDevice::ReadOther)));
    }
    void blurStrengthIsParsedAndBounded() {
        QCOMPARE(DesktopActions::parseBlurStrength(QStringLiteral("[Effect-blur]\nBlurStrength=7\n")), 7);
        QCOMPARE(DesktopActions::parseBlurStrength(QStringLiteral("[Plugins]\nBlurStrength=7\n[Effect-blur]\nNoiseStrength=3\n")), 0);
        QCOMPARE(DesktopActions::parseBlurStrength(QStringLiteral("[Effect-blur]\nBlurStrength=99\n")), 0);
        QCOMPARE(DesktopActions::parseBlurStrength(QStringLiteral("[Effect-blur]\nBlurStrengthX=4\nBlurStrength = 3\n")), 3);
        DesktopActions actions;
        for (const QJsonValue &bad : {QJsonValue(0), QJsonValue(16), QJsonValue(2.5), QJsonValue(QStringLiteral("9"))})
            QVERIFY(std::holds_alternative<protocol::Error>(actions.setBlur({{QStringLiteral("strength"), bad}})));
    }
    void welcomeStartsPendingAndOnlyAcceptsBool() {
        QTemporaryDir directory;
        Preferences preferences(directory.filePath(QStringLiteral("settings.json")));
        const auto values = std::get<QJsonObject>(preferences.read()).value(QStringLiteral("values")).toObject();
        QCOMPARE(values.value(QStringLiteral("welcomeCompleted")).toBool(true), false);
        QVERIFY(std::holds_alternative<protocol::Error>(preferences.patch({{QStringLiteral("welcomeCompleted"), QStringLiteral("yes")}})));
        QVERIFY(std::holds_alternative<QJsonObject>(preferences.patch({{QStringLiteral("welcomeCompleted"), true}})));
    }
    void invalidStoredPreferencesRecoverIndividually() {
        QTemporaryDir directory;
        const QString path = directory.filePath(QStringLiteral("settings.json"));
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(R"({"dockIconSize":999,"mode":"dark","pins":["../bad.desktop"]})");
        file.close();
        Preferences preferences(path);
        const auto values = std::get<QJsonObject>(preferences.read()).value(QStringLiteral("values")).toObject();
        QCOMPARE(values.value(QStringLiteral("mode")).toString(), QStringLiteral("dark"));
        QCOMPARE(values.value(QStringLiteral("dockIconSize")).toInt(), 56);
        QVERIFY(!values.value(QStringLiteral("pins")).toArray().contains(QStringLiteral("../bad.desktop")));
    }
    void catalogRejectsInvalidPaginationAndLaunch() {
        Applications applications;
        QVERIFY(std::holds_alternative<protocol::Error>(applications.list({{QStringLiteral("limit"), 500}})));
        QVERIFY(std::holds_alternative<protocol::Error>(applications.launch({{QStringLiteral("id"), QStringLiteral("../bad.desktop")}})));
        QVERIFY(std::holds_alternative<protocol::Error>(applications.launch({{QStringLiteral("id"), QStringLiteral("nova-test-definitely-missing.desktop")}})));
        const auto page = std::get<QJsonObject>(applications.list({{QStringLiteral("limit"), 1}}));
        QVERIFY(page.value(QStringLiteral("applications")).toArray().size() <= 1);
        QVERIFY(page.value(QStringLiteral("total")).toInt() >= 0);
    }
};
QTEST_GUILESS_MAIN(TestDesktop)
#include "tst_desktop.moc"
