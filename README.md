# FunkyClaude

A small C++/Qt Quick (QML) desktop app that plays a video **while Claude is
working** and **pauses it when Claude is idle / waiting for your input**.

It's a fun ambient indicator: kick off a task, the video starts grooving; the
moment Claude stops and hands control back to you, the video freezes.

## How it works

```
Claude Code hook  ──writes──▶  state file  ──watched by──▶  FunkyClaude (Qt/QML)
 (UserPromptSubmit,           ~/.funkyclaude/state           plays/pauses the video
  Stop, Notification)         ("working" / "idle")
```

- **Hooks** fire on Claude Code lifecycle events and run `hooks/funky-state.sh`,
  which writes a single keyword (`working` or `idle`) into a small state file.
- The Qt app (`ClaudeStateMonitor`) watches that file with `QFileSystemWatcher`
  (plus a 1 s polling safety net) and exposes a `working` property to QML.
- `Main.qml` binds playback to it: **play** when `working`, **pause** when idle.

The app also works standalone — there's a manual Play/Pause/Stop, a seek bar, an
"Open…" file picker, and a **Follow Claude** toggle. Pressing Play/Pause manually
drops out of follow mode; re-tick **Follow Claude** to hand control back.

## Building

Requires **Qt 6.5+** with the **Multimedia** module, CMake 3.21+, and a C++17
compiler.

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.7.x/<compiler>
cmake --build build
```

On Windows with MSVC, GitHub Actions builds this automatically — see
`.github/workflows/build.yml`, which installs Qt, builds with MSVC/Ninja, runs
`windeployqt`, and uploads a runnable artifact.

> Note: this project was authored in a headless environment without Qt
> installed, so it has not been compiled locally — rely on the CI build (or your
> own local build) to validate it.

## Running

```bash
# pass a video file as an argument, a --video flag, or the env var
./build/funkyclaude path/to/video.mp4
./build/funkyclaude --video path/to/video.mp4
FUNKYCLAUDE_VIDEO=path/to/video.mp4 ./build/funkyclaude
```

You can also launch it with no file and use **Open…** in the UI.

Options:

| Option | Description |
| --- | --- |
| `--video <path>` / positional | Video file to play. |
| `--state-file <path>` | State file to watch (default `~/.funkyclaude/state`). |
| `FUNKYCLAUDE_VIDEO` | Default video file. |
| `FUNKYCLAUDE_STATE_FILE` | Default state file (must match the hook script). |

## Wiring up the Claude Code hooks

1. Make the script executable:

   ```bash
   chmod +x hooks/funky-state.sh
   ```

2. Merge the `hooks` block from `hooks/settings.example.json` into your
   `~/.claude/settings.json` (or a project `.claude/settings.json`), updating the
   absolute path to `funky-state.sh`.

   The example wires:
   - `UserPromptSubmit` → `working` (you sent a prompt; Claude starts working)
   - `PreToolUse` / `PostToolUse` → `working` (re-asserts working on every tool
     call, so the state self-corrects during long tasks)
   - `Stop` / `SubagentStop` → `idle` (Claude finished its turn)
   - `Notification` → `idle` (Claude is waiting for input or permission)

3. Start `funkyclaude` with a video. Now the video plays while Claude works and
   pauses when it's your turn.

If you override `FUNKYCLAUDE_STATE_FILE`, set the same value for both the app and
the hook environment so they agree on the file.

### Windows

`funky-state.sh` is a bash script, so on Windows use the batch equivalent
`hooks/funky-state.bat` (no Git Bash/WSL required) and the
`hooks/settings.windows.example.json` config. It writes the same state file,
defaulting to `%USERPROFILE%\.funkyclaude\state` — the `state` file inside the
`.funkyclaude` folder, which the app creates on first launch.

Quick check (in `cmd`), with the app running:

```bat
hooks\funky-state.bat working   :: video should play
hooks\funky-state.bat idle      :: video should pause
```


## Project layout

```
CMakeLists.txt              # Qt6 build (Quick + Multimedia)
src/main.cpp                # entry point, CLI/env parsing, QML bootstrap
src/ClaudeStateMonitor.*    # watches the state file, exposes `working` to QML
qml/Main.qml                # video surface, controls, "Claude is working" badge
hooks/funky-state.sh        # writes the state file from a hook
hooks/settings.example.json # example Claude Code hook configuration
.github/workflows/build.yml # Windows/MSVC CI build
```
