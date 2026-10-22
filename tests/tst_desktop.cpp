// SPDX-License-Identifier: GPL-3.0-or-later
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
