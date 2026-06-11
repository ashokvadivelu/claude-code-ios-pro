#!/usr/bin/env bash
#
# session-start.sh — Claude Code SessionStart hook
# Prints project context at the start of every session.
# Hook output goes to stderr (visible to the user, not the model).
#

set -euo pipefail

PROJECT_NAME=$(basename "$(pwd)")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")
SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 | sed 's/^/  /' || echo "  Swift not on PATH")
XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "Xcode not on PATH")

# Find workspace/project/package
if compgen -G "*.xcworkspace" > /dev/null; then
    PROJECT_TYPE="workspace ($(ls -d *.xcworkspace | head -1))"
elif compgen -G "*.xcodeproj" > /dev/null; then
    PROJECT_TYPE="project ($(ls -d *.xcodeproj | head -1))"
elif [ -f "Package.swift" ]; then
    PROJECT_TYPE="Swift package"
else
    PROJECT_TYPE="(no Xcode/SPM project detected)"
fi

# Booted simulators (if any)
BOOTED_SIMS=$(xcrun simctl list devices booted 2>/dev/null | grep -E "iPhone|iPad" | head -3 || echo "  (none booted)")

cat >&2 <<EOF
╭─────────────────────────────────────────────────────────────╮
│  📱 $PROJECT_NAME — $BRANCH
│  $PROJECT_TYPE
│  $XCODE_VERSION
$SWIFT_VERSION
│
│  Booted simulators:
$(echo "$BOOTED_SIMS" | sed 's/^/│  /')
│
│  Reminder: use XcodeBuildMCP tools, never raw xcodebuild.
╰─────────────────────────────────────────────────────────────╯
EOF

exit 0
