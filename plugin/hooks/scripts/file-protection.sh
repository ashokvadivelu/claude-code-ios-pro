#!/usr/bin/env bash
#
# file-protection.sh — Claude Code PreToolUse hook for Edit|Write|MultiEdit
#
# Refuses to modify sensitive files: secrets, signing material, lockfiles,
# entitlements, the git directory, and the lint configs themselves.
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

FILE=$(jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null < /dev/stdin)
[ -z "$FILE" ] && exit 0

# --- Hard-protected patterns ---
# Any file path containing one of these substrings is refused.
PROTECTED_PATTERNS=(
    # Environment / secrets
    ".env"
    ".env.local"
    ".env.production"
    ".env.development"
    "Secrets.swift"
    "Secrets.plist"
    "Secrets.xcconfig"
    "APIKeys.swift"
    "Credentials.swift"
    # Apple signing / config
    "GoogleService-Info.plist"
    ".p8"
    ".p12"
    ".mobileprovision"
    ".provisionprofile"
    ".cer"
    ".certSigningRequest"
    ".entitlements"
    # Git internals
    ".git/"
    ".gitattributes"
    # Lockfiles — Claude should never edit these by hand
    "Podfile.lock"
    "Package.resolved"
    "Cartfile.resolved"
    "Gemfile.lock"
    # Fastlane sensitive
    "fastlane/Appfile"
    "fastlane/Matchfile"
    "fastlane/.env"
    # Lint configs — protect from accidental "fix" that loosens rules
    ".swiftlint.yml"
    ".swiftformat"
    # CI configs that hold deploy keys
    ".github/workflows/release"
    ".gitlab-ci.yml"
    "bitrise.yml"
)

# Load extra patterns from the project (one per line, # comments ok)
if [ -f ".claude/protected-files" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && [ "${line:0:1}" != "#" ] && PROTECTED_PATTERNS+=("$line")
    done < ".claude/protected-files"
fi

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    case "$FILE" in
        *"$pattern"*)
            echo "🛡  Protected file — refusing to modify: $FILE (matched: $pattern)" >&2
            echo "   Edit this file yourself outside Claude Code if necessary." >&2
            exit 2
            ;;
    esac
done

exit 0
