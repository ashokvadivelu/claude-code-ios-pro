#!/usr/bin/env bash
#
# session-summary.sh — Claude Code SessionEnd hook
# Appends a one-line summary of the session to .claude/session.log
#

set -euo pipefail

LOG_DIR=".claude"
LOG_FILE="$LOG_DIR/session.log"

# Bail if we're not in a claude project
[ -d "$LOG_DIR" ] || exit 0

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")

# Files modified in the working tree right now
MODIFIED_COUNT=$(git status --porcelain 2>/dev/null | wc -l | xargs)

# Anything in stdin? (Claude Code passes session metadata here)
META=$(cat 2>/dev/null || echo "")

{
    echo "[$TIMESTAMP] branch=$BRANCH modified_files=$MODIFIED_COUNT"
    [ -n "$META" ] && echo "  meta: $META"
} >> "$LOG_FILE"

exit 0
