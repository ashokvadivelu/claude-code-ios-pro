---
description: Code review on the current git diff using the swift-reviewer agent
argument-hint: [base-branch]
allowed-tools: Read, Grep, Glob, Bash(git *), Task
---

# Review

Run a senior Swift code review on the current changeset.

## Steps

1. Determine the base branch:
   - If `$ARGUMENTS` provided, use it
   - Else default to `main` (fall back to `master` if `main` doesn't exist)
2. Capture the diff: `git diff <base>...HEAD --name-only` for the file list, `git diff <base>...HEAD` for the patch.
3. For each changed Swift file, read the full file (not just the diff hunks — context matters).
4. Hand off to the `swift-reviewer` subagent with the diff and file contents.
5. If any cryptographic code was touched, also invoke `crypto-reviewer`.
6. If any security-sensitive code was touched (Keychain, networking, auth, biometrics), also invoke `ios-security-auditor`.

## Output

A consolidated review report combining the subagents' findings. Group by severity: Blocking → Suggestions → Nits.

Do not modify any files. Review only.
