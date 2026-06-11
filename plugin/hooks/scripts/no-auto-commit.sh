#!/usr/bin/env bash
#
# no-auto-commit.sh — Claude Code PreToolUse hook for Bash
#
# Blocks Claude from running git commit / git push / git tag without explicit
# user confirmation. The user should always review the diff and commit by hand.
#
# Reads JSON from stdin, exit 2 to block.
#

set -uo pipefail

# Require jq — without it the hook would fail open and silently let
# everything through, which the user would (correctly) interpret as 'hooks broken'.
if ! command -v jq &> /dev/null; then
    echo "❌ Hook $(basename "$0") requires jq. Install with: brew install jq" >&2
    exit 2
fi

COMMAND=$(jq -r '.tool_input.command // empty' 2>/dev/null < /dev/stdin)
[ -z "$COMMAND" ] && exit 0

# Patterns we refuse to run on the user's behalf. The user can always run them
# themselves outside the Claude session.
declare -a NO_COMMIT_PATTERNS=(
    'git commit'
    'git commit -'        # -m, --amend, etc.
    'git commit$'         # bare `git commit`
    'git push'
    'git tag'
    'git merge'
    'git rebase'
    'git cherry-pick'
    'git revert'
)

for pattern in "${NO_COMMIT_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        cat >&2 <<EOF
🛑 No-auto-commit policy: refusing to run "$COMMAND".

Claude should not commit, push, tag, merge, rebase, cherry-pick, or revert on
your behalf. Review the diff yourself (\`git status\`, \`git diff\`) and run the
git command in your own terminal when you're ready.

If you want Claude to *prepare* a commit message, ask for one as text — Claude
can suggest it without running git.
EOF
        exit 2
    fi
done

exit 0
