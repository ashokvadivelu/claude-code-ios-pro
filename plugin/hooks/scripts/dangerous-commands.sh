#!/usr/bin/env bash
#
# dangerous-commands.sh — Claude Code PreToolUse hook for Bash
# Blocks destructive shell commands. Reads JSON from stdin, exit 2 to block.
#

set -euo pipefail

# Require jq — without it the hook would fail open and silently let
# everything through, which the user would (correctly) interpret as 'hooks broken'.
if ! command -v jq &> /dev/null; then
    echo "❌ Hook $(basename "$0") requires jq. Install with: brew install jq" >&2
    exit 2
fi

COMMAND=$(jq -r '.tool_input.command // empty' 2>/dev/null < /dev/stdin)

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Patterns that are never OK
declare -a HARD_BLOCKS=(
    'rm -rf /'              # nuke from root
    'rm -rf ~'              # nuke home
    'rm -rf \$HOME'         # nuke home (escaped)
    'rm -rf \*'             # nuke working dir contents
    ':(){:|:&};:'           # fork bomb
    'mkfs\.'                # format
    'dd if=.+ of=/dev/'     # raw write to device
    'chmod -R 777 /'        # break the OS
    '> /dev/sda'            # overwrite disk
    'curl .+ \| sudo bash'  # remote-code-execution pipeline
    'wget .+ \| sudo sh'    # same
    'wget .+ \| bash'       # same (slightly less terrible)
)

# Patterns that are usually wrong but might be intentional — warn but block
declare -a SOFT_BLOCKS=(
    'git push --force'
    'git push -f '
    'git reset --hard origin/main'
    'git reset --hard origin/master'
    'git clean -fdx'
    'killall Xcode'
)

for pattern in "${HARD_BLOCKS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        echo "🚫 Refusing dangerous command: $COMMAND" >&2
        exit 2
    fi
done

for pattern in "${SOFT_BLOCKS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        echo "⚠  Destructive command refused — run it yourself if intentional: $COMMAND" >&2
        exit 2
    fi
done

exit 0
