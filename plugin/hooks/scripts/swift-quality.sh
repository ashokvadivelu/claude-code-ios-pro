#!/usr/bin/env bash
#
# swift-quality.sh — Claude Code PostToolUse hook for Edit|Write|MultiEdit
#
# After any Swift file is edited:
#   1. Auto-format with SwiftFormat (if installed and a config exists)
#   2. Lint with SwiftLint (if installed and a config exists)
#   3. Surface violations to Claude via stderr, exit 2 to block on errors
#
# Strictness controlled by CLAUDE_IOS_LINT_MODE env var:
#   strict   — any violation (warning or error) blocks Claude
#   balanced — only error-level violations block (default)
#   lenient  — violations reported but never block
#
# Reads JSON from stdin.
#

set -uo pipefail

# Require jq — without it the hook would fail open and silently let
# everything through, which the user would (correctly) interpret as 'hooks broken'.
if ! command -v jq &> /dev/null; then
    echo "❌ Hook $(basename "$0") requires jq. Install with: brew install jq" >&2
    exit 2
fi

FILE=$(jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null < /dev/stdin)

# Only act on Swift files
case "$FILE" in
    *.swift) ;;
    *) exit 0 ;;
esac

# Skip if file no longer exists (deleted, moved, etc.)
[ -f "$FILE" ] || exit 0

MODE="${CLAUDE_IOS_LINT_MODE:-balanced}"

# --- 1. SwiftFormat (auto-fix) ---
if command -v swiftformat &> /dev/null; then
    # Use project config if present, otherwise SwiftFormat defaults
    if [ -f ".swiftformat" ]; then
        swiftformat "$FILE" --config .swiftformat --quiet 2>/dev/null || true
    else
        swiftformat "$FILE" --quiet 2>/dev/null || true
    fi
fi

# --- 2. SwiftLint ---
LINT_OUTPUT=""
HAS_ERROR=0
HAS_WARNING=0

if command -v swiftlint &> /dev/null; then
    # Prefer project config; SwiftLint will use its own defaults if none exists.
    LINT_RAW=$(swiftlint lint --path "$FILE" --quiet --reporter csv 2>&1 || true)

    if [ -n "$LINT_RAW" ]; then
        # CSV columns: file,line,col,type(Warning|Error),rule,message
        # Show up to 5 most important violations to avoid context-drowning.
        LINT_OUTPUT=$(echo "$LINT_RAW" | head -5)

        echo "$LINT_RAW" | grep -q ",Error," && HAS_ERROR=1
        echo "$LINT_RAW" | grep -q ",Warning," && HAS_WARNING=1
    fi
fi

# --- 3. Report and decide ---
if [ -n "$LINT_OUTPUT" ]; then
    echo "🧹 SwiftLint findings in $FILE (mode=$MODE):" >&2
    echo "$LINT_OUTPUT" >&2

    case "$MODE" in
        strict)
            [ "$HAS_ERROR" = "1" ] || [ "$HAS_WARNING" = "1" ] && {
                echo "   ↳ strict mode: fix the above before continuing." >&2
                exit 2
            }
            ;;
        balanced)
            [ "$HAS_ERROR" = "1" ] && {
                echo "   ↳ error-level violation — fix before continuing." >&2
                exit 2
            }
            ;;
        lenient)
            : # report only
            ;;
    esac
fi

exit 0
