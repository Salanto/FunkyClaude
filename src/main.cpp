#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QDir>
#include <QUrl>

#include "ClaudeStateMonitor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("FunkyClaude"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("FunkyClaude"));
    QGuiApplication::setOrganizationName(QStringLiteral("Salanto"));

    QCommandLineParser parser;
    parser.setApplicationDescription(
        "Plays a video while Claude is working and pauses it while Claude is idle.");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption videoOpt({QStringLiteral("v"), QStringLiteral("video")},
                                QStringLiteral("Video file to play."),
                                QStringLiteral("path"));
    QCommandLineOption stateOpt({QStringLiteral("s"), QStringLiteral("state-file")},
                                QStringLiteral("State file written by the Claude hooks "
                                               "(default: ~/.funkyclaude/state)."),
                                QStringLiteral("path"));
    parser.addOption(videoOpt);
    parser.addOption(stateOpt);
    parser.addPositionalArgument(QStringLiteral("video"),
                                 QStringLiteral("Video file to play (optional)."));
    parser.process(app);

    // Resolve the video source: --video, then a positional argument, then the
    // FUNKYCLAUDE_VIDEO environment variable. May be empty (open one in the UI).
    QString videoPath = parser.value(videoOpt);
    if (videoPath.isEmpty()) {
        const QStringList positional = parser.positionalArguments();
        if (!positional.isEmpty())
            videoPath = positional.first();
    }
    if (videoPath.isEmpty())
        videoPath = qEnvironmentVariable("FUNKYCLAUDE_VIDEO");

    QUrl videoUrl;
    if (!videoPath.isEmpty())
        videoUrl = QUrl::fromUserInput(videoPath, QDir::currentPath(), QUrl::AssumeLocalFile);

    // The state file: --state-file, then FUNKYCLAUDE_STATE_FILE, then default.
    QString stateFile = parser.value(stateOpt);
    if (stateFile.isEmpty())
        stateFile = qEnvironmentVariable("FUNKYCLAUDE_STATE_FILE");

    ClaudeStateMonitor monitor;
    monitor.setStateFilePath(stateFile); // empty -> default location
    monitor.start();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("claudeState"), &monitor);
    engine.rootContext()->setContextProperty(QStringLiteral("initialVideoSource"), videoUrl);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule("FunkyClaude", "Main");

    return app.exec();
}
