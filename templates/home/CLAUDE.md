# Global Claude Code Preferences — iOS Senior Developer

> This file lives at `~/.claude/CLAUDE.md` and applies to every project you open.
> Project-specific instructions in `./CLAUDE.md` override anything here.

## Who I am

A senior iOS developer. Default toolchain: latest stable Xcode, Swift 6 with strict concurrency, SwiftUI-first, Swift Package Manager. I prefer working code over working comments, value types over reference types, and explicit dependencies over hidden ones.

## Defaults (override per project)

| Choice | Default | Override in |
|---|---|---|
| Language | Swift 6.0+ | Project CLAUDE.md |
| Concurrency mode | strict | Project CLAUDE.md |
| UI framework | SwiftUI | Project CLAUDE.md |
| Min deployment target | iOS 17.0 | Project CLAUDE.md |
| Architecture | MVVM with `@Observable` | Project CLAUDE.md |
| Persistence | SwiftData when iOS 17+, Core Data when legacy | Project CLAUDE.md |
| Networking | `URLSession` + `async/await` | Project CLAUDE.md |
| Testing | Swift Testing (`@Test`) for new code | Project CLAUDE.md |
| Dependency manager | Swift Package Manager | Project CLAUDE.md |
| Lint | SwiftLint + SwiftFormat | Project CLAUDE.md |

## House rules

### Always
- Use `guard` for early exits, not nested `if let`
- Use `os.Logger` for logging — never `print` in committed code
- Use `async/await` over completion handlers
- Use `Sendable` types when crossing actor boundaries
- Use `@MainActor` on UI-bound state
- Write a `#Preview` for every new SwiftUI view
- Inject dependencies via initialiser or `@Environment` — no singletons except logger / telemetry
- Pin SPM dependencies to specific versions for production code
- Prefer Apple's `CryptoKit` over `CommonCrypto`
- Use `SecRandomCopyBytes` for any security-sensitive randomness
- Store credentials in Keychain, never `UserDefaults`

### Never (without explicit user override)
- **Never run `git commit`, `git push`, `git tag`, `git merge`, `git rebase`, `git cherry-pick`, or `git revert`** — the user reviews the diff and commits manually. You can stage with `git add` and you can *propose* a commit message in chat, but don't execute the commit.
- Force-unwrap (`!`) without a comment explaining why it cannot be nil
- `try!` outside test code
- `fatalError` in a path the user can reach
- Use `UserDefaults` for tokens, keys, passwords, or PII
- Use `NSAllowsArbitraryLoads = true` in `Info.plist`
- Use MD5 / SHA-1 / DES / RC4 for security
- Use `arc4random` / `Int.random(in:)` for cryptographic randomness
- Add `print()` statements to release code
- Add commented-out code
- Add a TODO without a ticket reference
- Add "Generated with Claude" or "Co-Authored-By: Claude" to commit messages
- **Edit sensitive files**: `.env*`, `*Secrets.*`, `GoogleService-Info.plist`, `.entitlements`, `.mobileprovision`, `.p8`, `.p12`, lockfiles, `.git/`, `.swiftlint.yml`, `.swiftformat`. The file-protection hook will block these; don't try to work around it.

## How I want answers

- **Direct.** State the answer first, then the reasoning. Don't bury the lead.
- **Cite Apple.** When recommending an API, link to the developer documentation page.
- **Show, don't tell.** Code examples > prose descriptions.
- **One screen.** If the answer needs more, propose creating a planning document.
- **Honest uncertainty.** "I don't know" is better than a confident wrong answer. Verify with `WebSearch` / `WebFetch` when the answer depends on current Apple guidance.

## Tools

- **XcodeBuildMCP** is the only acceptable way to build, test, install, and launch. Never raw `xcodebuild` from `Bash`.
- **`xcrun mcpbridge`** (Xcode 26.3+) for native Xcode IDE access and SwiftUI preview rendering.
- **GitHub MCP** for PR / issue / CI operations.

## Default planning workflow

For non-trivial features (more than a single file change):

1. Use `/plan-feature <name>` first — Opus + ultrathink, writes a plan to `docs/tasks/<name>-plan.md`
2. Review the plan together before implementation
3. Implement phase-by-phase, with tests added in the same change
4. Run `/review` against the base branch before requesting merge
5. Run `/security-audit` before any release that touches user data, credentials, or network

## Git workflow

The user reviews changes and commits manually. Claude:

- **Never** runs `git commit`, `git push`, `git tag`, `git merge`, `git rebase`, `git cherry-pick`, `git revert`. Plugin hook blocks these.
- Can run `git status`, `git diff`, `git log`, `git branch`, `git stash`, `git add` to inspect or stage.
- Can *suggest* a commit message in chat for the user to copy.
- After making changes, says something like: *"Changes ready. Review with `git diff` and commit when you're satisfied."*

## File protection

The plugin's `file-protection` hook refuses to modify:

- `.env*`, `*Secrets.*`, `APIKeys.*`, `Credentials.*`
- `GoogleService-Info.plist`, `*.entitlements`, `*.mobileprovision`, `*.provisionprofile`, `*.p8`, `*.p12`, `*.cer`
- `.git/`, lockfiles (`Podfile.lock`, `Package.resolved`, `Cartfile.resolved`)
- Lint configs: `.swiftlint.yml`, `.swiftformat` (touch these only with explicit human review — they govern every future edit)
- `fastlane/Appfile`, `fastlane/Matchfile`, `fastlane/.env`

If you genuinely need to edit one of these, do it manually outside Claude Code.

## SwiftLint + SwiftFormat enforcement

Every Swift file edit triggers the `swift-quality` hook:

1. SwiftFormat auto-fixes formatting (uses `.swiftformat` config if present)
2. SwiftLint reports violations (uses `.swiftlint.yml` config)
3. Error-level violations **block** until fixed (configurable via `CLAUDE_IOS_LINT_MODE`)

Don't try to bypass it. If a rule is too strict for the codebase, update `.swiftlint.yml` (with human review) — don't sneak around the hook.
