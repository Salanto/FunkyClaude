import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia

ApplicationWindow {
    id: win
    width: 960
    height: 600
    minimumWidth: 480
    minimumHeight: 320
    visible: true
    title: qsTr("FunkyClaude")
    color: "#101014"

    // When true (the default), playback follows Claude's working/idle state.
    // Manually pressing Play/Pause drops out of follow mode so the user keeps
    // control until they re-enable it.
    property bool followClaude: true

    function hasSource() {
        return player.source !== undefined && player.source.toString() !== ""
    }

    // Drive playback from Claude's state when in follow mode.
    function syncPlayback() {
        if (!followClaude || !hasSource())
            return
        if (claudeState.working) {
            if (player.playbackState !== MediaPlayer.PlayingState)
                player.play()
        } else if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause()
        }
    }

    MediaPlayer {
        id: player
        videoOutput: videoOut
        audioOutput: AudioOutput { id: audioOut }
        loops: MediaPlayer.Infinite
        source: initialVideoSource
        onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError)
                statusLabel.text = qsTr("Playback error: ") + errorString
        }
    }

    Connections {
        target: claudeState
        function onWorkingChanged() { win.syncPlayback() }
    }

    Component.onCompleted: syncPlayback()
    onFollowClaudeChanged: syncPlayback()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- Video surface -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"

            VideoOutput {
                id: videoOut
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
            }

            // Placeholder shown until a video is loaded.
            ColumnLayout {
                anchors.centerIn: parent
                visible: !win.hasSource()
                spacing: 8
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "🎬"
                    font.pixelSize: 48
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No video loaded — click \"Open…\"")
                    color: "#9aa0a6"
                }
            }

            // "Claude is working" badge overlaid on the video.
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 12
                visible: win.hasSource()
                radius: 14
                height: 28
                width: badgeRow.implicitWidth + 20
                color: claudeState.working ? "#1e3a2a" : "#3a1e1e"
                border.color: claudeState.working ? "#2ecc71" : "#e74c3c"
                border.width: 1
                opacity: 0.92

                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: claudeState.working ? "#2ecc71" : "#e74c3c"
                        SequentialAnimation on opacity {
                            running: claudeState.working
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 700 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 700 }
                        }
                    }
                    Label {
                        text: claudeState.working ? qsTr("Claude is working")
                                                   : qsTr("Claude is idle")
                        color: "white"
                        font.pixelSize: 12
                    }
                }
            }
        }

        // ---- Seek bar ------------------------------------------------------
        Slider {
            id: seekBar
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            from: 0
            to: player.duration > 0 ? player.duration : 1
            enabled: win.hasSource() && player.seekable
            value: player.position

            onMoved: player.position = value
        }

        // ---- Controls ------------------------------------------------------
        ToolBar {
            Layout.fillWidth: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                Button {
                    text: player.playbackState === MediaPlayer.PlayingState
                          ? qsTr("⏸ Pause") : qsTr("▶ Play")
                    enabled: win.hasSource()
                    onClicked: {
                        // Manual control overrides follow mode.
                        win.followClaude = false
                        if (player.playbackState === MediaPlayer.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                }

                Button {
                    text: qsTr("⏹ Stop")
                    enabled: win.hasSource()
                    onClicked: {
                        win.followClaude = false
                        player.stop()
                    }
                }

                Button {
                    text: qsTr("Open…")
                    onClicked: fileDialog.open()
                }

                Label {
                    id: statusLabel
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: "#c8ccd0"
                    text: qsTr("Claude: ") + claudeState.statusText
                          + "   •   " + win.formatTime(player.position)
                          + " / " + win.formatTime(player.duration)
                }

                CheckBox {
                    text: qsTr("Follow Claude")
                    checked: win.followClaude
                    onToggled: win.followClaude = checked
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Choose a video file")
        nameFilters: [qsTr("Video files (*.mp4 *.m4v *.mkv *.mov *.avi *.webm *.ogv)"),
                      qsTr("All files (*)")]
        onAccepted: {
            player.source = selectedFile
            win.followClaude = true
            player.play()
            win.syncPlayback()
        }
    }

    function formatTime(ms) {
        if (ms <= 0)
            return "0:00"
        var totalSeconds = Math.floor(ms / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
