// SPDX-License-Identifier: GPL-3.0-or-later
#include "Router.h"
#include "Server.h"
#include "WaylandProbe.h"

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QSocketNotifier>
#include <QTextStream>

#include <cerrno>
#include <chrono>
#include <optional>
#include <csignal>
#include <cstdio>
#include <sys/stat.h>
#include <unistd.h>

namespace {

int g_signalPipe[2] = {-1, -1};

void onSignal(int)
{
    const char byte = 1;
    // write() es async-signal-safe; el bucle de Qt hace el cierre limpio.
    [[maybe_unused]] const auto n = ::write(g_signalPipe[1], &byte, 1);
}

bool installSignalHandlers(QCoreApplication &app)
{
    if (::pipe(g_signalPipe) != 0) {
        return false;
    }
    auto *notifier = new QSocketNotifier(g_signalPipe[0], QSocketNotifier::Read, &app);
    QObject::connect(notifier, &QSocketNotifier::activated, &app, [] {
        char byte = 0;
        [[maybe_unused]] const auto n = ::read(g_signalPipe[0], &byte, 1);
        QCoreApplication::quit();
    });
    struct sigaction action{};
    action.sa_handler = onSignal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    sigaction(SIGTERM, &action, nullptr);
    sigaction(SIGINT, &action, nullptr);
    return true;
}

// Crea (o corrige) el directorio del socket: propiedad del usuario y 0700.
bool ensurePrivateDirectory(const QString &path, QString *error)
{
    const QByteArray native = QFile::encodeName(path);
    if (::mkdir(native.constData(), 0700) != 0 && errno != EEXIST) {
        *error = QStringLiteral("no se pudo crear %1").arg(path);
        return false;
    }
    struct stat info{};
    if (::lstat(native.constData(), &info) != 0 || !S_ISDIR(info.st_mode)) {
        *error = QStringLiteral("%1 no es un directorio").arg(path);
        return false;
    }
    if (info.st_uid != ::getuid()) {
        *error = QStringLiteral("%1 pertenece a otro usuario").arg(path);
        return false;
    }
    if ((info.st_mode & 077) != 0 && ::chmod(native.constData(), 0700) != 0) {
        *error = QStringLiteral("no se pudo restringir %1 a 0700").arg(path);
        return false;
    }
    return true;
}

QString defaultSocketPath()
{
    const QString runtime = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (runtime.isEmpty()) {
        return {};
    }
    return runtime + QStringLiteral("/novashell/platform.sock");
}

} // namespace

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("nova-platform"));
    QCoreApplication::setApplicationVersion(QStringLiteral(NOVA_VERSION));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Servicio de plataforma de NovaShell"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption socketOption(QStringLiteral("socket"),
        QStringLiteral("Ruta del socket (por defecto $XDG_RUNTIME_DIR/novashell/platform.sock)."),
        QStringLiteral("ruta"));
    parser.addOption(socketOption);
    parser.process(app);

    QTextStream err(stderr);

    if (::getuid() == 0) {
        err << "nova-platform no debe ejecutarse como root.\n";
        return 2;
    }

    const QString socketPath = parser.isSet(socketOption)
        ? parser.value(socketOption) : defaultSocketPath();
    if (socketPath.isEmpty()) {
        err << "XDG_RUNTIME_DIR no está definido; usa --socket.\n";
        return 2;
    }

    QString error;
    if (!ensurePrivateDirectory(QFileInfo(socketPath).absolutePath(), &error)) {
        err << error << '\n';
        return 1;
    }

    if (!installSignalHandlers(app)) {
        err << "no se pudieron instalar los manejadores de señales\n";
        return 1;
    }

    nova::Router router = nova::Router::makeDefault();
    // Los globals del compositor no cambian durante la sesión: se cachea el
    // primer sondeo correcto. Un fallo (compositor aún no listo) se reintenta
    // en la siguiente petición. Plazo acotado: nunca bloquea más de 500 ms.
    router.add(QStringLiteral("compositor.capabilities"),
        [cache = std::optional<QJsonObject>()](const QJsonObject &) mutable -> nova::Reply {
            if (cache) {
                return *cache;
            }
            const nova::WaylandGlobals globals =
                nova::probeWaylandGlobals(std::chrono::milliseconds(500));
            QJsonObject result = nova::compositorCapabilities(globals);
            if (globals.available) {
                cache = result;
            }
            return result;
        });
    nova::Server server(std::move(router));
    if (!server.listen(socketPath, &error)) {
        err << error << '\n';
        return 1;
    }

    return QCoreApplication::exec();
}
