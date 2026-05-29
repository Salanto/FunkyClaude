#!/usr/bin/env bash
#
# funky-state.sh — write FunkyClaude's state file from a Claude Code hook.
#
# Usage:  funky-state.sh working|idle
#
# Called by Claude Code hooks (see hooks/settings.example.json). It writes a
# single keyword into the state file that the FunkyClaude app watches:
#
#   working -> Claude is thinking/working  -> video plays
#   idle    -> Claude is waiting for input -> video pauses
#
# The state file location can be overridden with FUNKYCLAUDE_STATE_FILE so it
# matches whatever you pass to the app via --state-file. Keep them in sync.

set -euo pipefail

STATE_FILE="${FUNKYCLAUDE_STATE_FILE:-$HOME/.funkyclaude/state}"
STATE="${1:-idle}"

case "$STATE" in
    working|thinking|busy) STATE="working" ;;
    *)                     STATE="idle" ;;
esac

mkdir -p "$(dirname "$STATE_FILE")"

# Write atomically so the watcher always sees a complete value.
TMP="$(mktemp "${STATE_FILE}.XXXXXX")"
printf '%s\n' "$STATE" > "$TMP"
mv -f "$TMP" "$STATE_FILE"
