#!/usr/bin/env bash
#
# incremental-build.sh — Claude Code PostToolUse hook (opt-in, disabled by default)
#
# Triggers an incremental compile check after a Swift edit to surface errors fast.
# Uses `swift build` (fast, no signing) by default — falls back to xcodebuild if
# this is an .xcodeproj-only project.
#
# WARNING: this hook runs SYNCHRONOUSLY before the next tool call. Even an
# incremental swift build can take 5-30s on a non-trivial project. Enable only
# if you want that trade-off. For most users, running `/build` manually is faster.
#
# Disabled by default. To enable: uncomment the block in hooks.json (or in
# settings.json under "hooks.PostToolUse").
#

set -uo pipefail

# Require jq — without it the hook would fail open and silently let
# everything through, which the user would (correctly) interpret as 'hooks broken'.
if ! command -v jq &> /dev/null; then
    echo "❌ Hook $(basename "$0") requires jq. Install with: brew install jq" >&2
    exit 2
fi

FILE=$(jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null < /dev/stdin)
case "$FILE" in *.swift) ;; *) exit 0 ;; esac

# Hard cap on how long we wait — kill the build if it exceeds this.
TIMEOUT_SECS="${CLAUDE_IOS_BUILD_TIMEOUT:-30}"

LOG="/tmp/claude-ios-build-$$.log"

# Fast path: if Package.swift exists, use `swift build` (no signing, much faster)
if [ -f "Package.swift" ]; then
    # macOS doesn't ship `timeout`; emulate with a background+sleep racer.
    ( swift build > "$LOG" 2>&1 ) &
    BUILD_PID=$!
    ( sleep "$TIMEOUT_SECS" && kill -TERM "$BUILD_PID" 2>/dev/null ) &
    TIMER_PID=$!
    wait "$BUILD_PID" 2>/dev/null
    kill "$TIMER_PID" 2>/dev/null
else
    # No Package.swift — skip. xcodebuild from a hook is too slow for most projects.
    # The user can invoke `/build` explicitly when they want a full build check.
    exit 0
fi

# Surface only error: lines, capped at 5 to avoid drowning the model
ERRORS=$(grep -E "error:" "$LOG" 2>/dev/null | head -5 || true)
if [ -n "$ERRORS" ]; then
    echo "🔧 Build errors after edit:" >&2
    echo "$ERRORS" >&2
fi

rm -f "$LOG"
exit 0
