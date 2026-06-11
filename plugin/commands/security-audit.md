---
description: Full OWASP MASVS-aligned security audit of the iOS project
argument-hint: [scope: --auth | --storage | --network | --crypto | --all]
allowed-tools: Read, Grep, Glob, Bash, Task, WebFetch
model: claude-opus-4-5-20250929
---

# Security Audit

Run a security audit on the current iOS project, aligned to OWASP MASVS.

## Steps

1. Determine scope from `$ARGUMENTS`:
   - `--auth` → authentication, biometrics, session handling
   - `--storage` → Keychain, UserDefaults, files, pasteboard, backups
   - `--network` → ATS, certificate pinning, TLS, deep links
   - `--crypto` → algorithms, key management, randomness
   - `--all` (default) → all of the above plus platform / privacy manifest / dependencies

2. Invoke the `ios-security-auditor` subagent with the chosen scope.
3. If `--crypto` or `--all`, also invoke `crypto-reviewer` on any crypto code found.
4. Consolidate findings into one report.

## Output

A single security audit report (Markdown) with:
- Summary count by severity
- Per-finding sections: location, evidence, risk, fix, references
- Suggested next steps (e.g. "engage a paid pen-test before App Store release if findings remain Critical")

Save the report to `docs/security/audit-<date>.md` so it's tracked over time.

This is a read-only audit. Do not modify code. The developer applies the fixes.
