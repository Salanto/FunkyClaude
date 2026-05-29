#include "ClaudeStateMonitor.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

ClaudeStateMonitor::ClaudeStateMonitor(QObject *parent)
    : QObject(parent)
    , m_stateFilePath(defaultStateFilePath())
{
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &ClaudeStateMonitor::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &ClaudeStateMonitor::reload);

    // Safety-net poll: cheap, and recovers if the watcher drops a file that
    // was replaced atomically (a common pattern for `mv tmp file`).
    m_poll.setInterval(1000);
    connect(&m_poll, &QTimer::timeout, this, &ClaudeStateMonitor::reload);
}

QString ClaudeStateMonitor::defaultStateFilePath()
{
    return QDir::homePath() + QStringLiteral("/.funkyclaude/state");
}

void ClaudeStateMonitor::setStateFilePath(const QString &path)
{
    const QString resolved = path.isEmpty() ? defaultStateFilePath() : path;
    if (resolved == m_stateFilePath)
        return;
    m_stateFilePath = resolved;
    emit stateFilePathChanged();
    ensureWatched();
    reload();
}

void ClaudeStateMonitor::start()
{
    ensureWatched();
    reload();
    m_poll.start();
}

void ClaudeStateMonitor::ensureWatched()
{
    // Make sure the containing directory exists so the hook scripts and the
    // directory watcher both have something to work with.
    const QFileInfo info(m_stateFilePath);
    QDir().mkpath(info.absolutePath());

    if (!m_watcher.files().isEmpty())
        m_watcher.removePaths(m_watcher.files());
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());

    // Watch the directory (catches creation) and the file (catches edits).
    m_watcher.addPath(info.absolutePath());
    if (info.exists())
        m_watcher.addPath(m_stateFilePath);
}

void ClaudeStateMonitor::reload()
{
    // Re-arm the file watch in case the file was just (re)created or replaced.
    if (QFileInfo::exists(m_stateFilePath) && !m_watcher.files().contains(m_stateFilePath))
        m_watcher.addPath(m_stateFilePath);

    QString content;
    QFile file(m_stateFilePath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        content = in.readAll();
    }

    content = content.trimmed().toLower();

    // Anything that looks like active work counts as "working"; everything
    // else (idle, waiting, done, missing/empty file) counts as idle.
    const bool isWorking =
        content == QLatin1String("working") ||
        content == QLatin1String("thinking") ||
        content == QLatin1String("busy") ||
        content == QLatin1String("run") ||
        content == QLatin1String("1") ||
        content == QLatin1String("true");

    if (isWorking != m_working) {
        m_working = isWorking;
        emit workingChanged();
    }
}
