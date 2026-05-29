#pragma once

#include <QObject>
#include <QString>
#include <QFileSystemWatcher>
#include <QTimer>

// Watches a small "state file" written by Claude Code hooks and exposes
// whether Claude is currently working (thinking) or idle (waiting for input)
// to QML. The file simply contains a keyword such as "working" or "idle".
//
// The file is watched with QFileSystemWatcher for instant reaction, plus a
// low-frequency polling timer as a safety net (some editors/atomic writers
// replace the file, which can drop the watch).
class ClaudeStateMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool working READ working NOTIFY workingChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY workingChanged)
    Q_PROPERTY(QString stateFilePath READ stateFilePath NOTIFY stateFilePathChanged)

public:
    explicit ClaudeStateMonitor(QObject *parent = nullptr);

    bool working() const { return m_working; }
    QString statusText() const { return m_working ? QStringLiteral("working") : QStringLiteral("idle"); }
    QString stateFilePath() const { return m_stateFilePath; }

    // Pass an empty string to use the default location.
    void setStateFilePath(const QString &path);

    // Begins watching. Performs an initial read of the current state.
    void start();

    // Default state file shared with the hook scripts: ~/.funkyclaude/state
    static QString defaultStateFilePath();

signals:
    void workingChanged();
    void stateFilePathChanged();

private slots:
    void reload();

private:
    void ensureWatched();

    QString m_stateFilePath;
    bool m_working = false;
    QFileSystemWatcher m_watcher;
    QTimer m_poll;
};
