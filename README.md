# Claude Code iOS Pro

> A production-grade Claude Code setup for senior iOS developers — agents, hooks, skills, commands, MCP connectors and team-shareable CLAUDE.md templates. Install in one command.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://docs.claude.com/en/docs/claude-code)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios)

This is the setup I wish I'd had on day one with Claude Code on an iOS project. It bundles eight specialised subagents, seven slash commands, six lifecycle hooks, a curated MCP connector list, and copy-ready `CLAUDE.md` templates for the global, project, and local scopes.

It's **opinionated but generic**: Swift 6 + SwiftUI first, MVVM with `@Observable` as the default architecture (overridable per-project), Swift Testing over XCTest, security-first defaults aligned to OWASP MASVS. Works for hobby apps, side projects, and production codebases.

---

## What's inside

| Component | Count | What it does |
|---|---|---|
| **Subagents** | 8 | Architecture, code review, SwiftUI, security audit, crypto review, testing, research, build doctor |
| **Slash commands** | 7 | `/build`, `/test`, `/run`, `/plan-feature`, `/review`, `/security-audit`, `/clean-derived` |
| **Hooks** | 7 | Session start, file protection, dangerous-command guard, **no-auto-commit guard**, SwiftLint/SwiftFormat enforcer, incremental build, session summary |
| **Skills** | 1 | `ios-bootstrap` — scaffolds a new feature module following the conventions |
| **MCP connectors** | 5 recommended | XcodeBuildMCP, Apple `mcpbridge`, sosumi (Apple docs), GitHub, filesystem |
| **CLAUDE.md templates** | 3 | Global (`~/.claude/`), project (`./`), local override (gitignored) |
| **Settings templates** | 3 | Same three scopes, with sensible permission allow/deny lists |

---

## Quick install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/claude-code-ios-pro/main/install.sh | bash
```

The installer is interactive: it asks before overwriting anything, backs up existing files to `~/.claude/backup-<timestamp>/`, and lets you skip parts you don't want.

> **Heads up:** the URL above is a placeholder. Replace `<your-username>` with your GitHub handle after you push this repo.

---

## Install as a Claude Code plugin (recommended for teams)

If your team shares a repo, the plugin install adds the agents/commands/hooks/skills without touching personal config:

```bash
# Inside any Claude Code session
/plugin marketplace add <your-username>/claude-code-ios-pro
/plugin install ios-dev-pro@claude-code-ios-pro
```

To make installation automatic for every teammate, add this to your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "ios-dev-pro@claude-code-ios-pro": true
  },
  "extraKnownMarketplaces": {
    "claude-code-ios-pro": {
      "source": {
        "source": "github",
        "repo": "<your-username>/claude-code-ios-pro"
      }
    }
  }
}
```

---

## Install manually (full control)

If you'd rather pick-and-choose, every file lives at a known path:

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/claude-code-ios-pro.git
cd claude-code-ios-pro

# 2. Copy global templates (your personal iOS-dev brain)
mkdir -p ~/.claude
cp templates/home/CLAUDE.md ~/.claude/CLAUDE.md
cp templates/home/settings.json ~/.claude/settings.json

# 3. Copy agents/commands/hooks into the user scope
cp -R plugin/agents ~/.claude/agents
cp -R plugin/commands ~/.claude/commands
cp -R plugin/hooks/scripts ~/.claude/hooks
chmod +x ~/.claude/hooks/*.sh

# 4. In your iOS project, copy the project templates
cd /path/to/your/ios/project
mkdir -p .claude
cp /path/to/claude-code-ios-pro/templates/project/CLAUDE.md ./CLAUDE.md
cp /path/to/claude-code-ios-pro/templates/project/settings.json .claude/settings.json
cp /path/to/claude-code-ios-pro/templates/project/.mcp.json ./.mcp.json
```

---

## The subagent team

Each subagent runs in an isolated context window — you don't lose your main thread when they work.

| Name | Model | Trigger | Role |
|---|---|---|---|
| `ios-architect` | Opus | Architecture / module / refactor questions | System design, layer boundaries, dependency direction |
| `swift-reviewer` | Sonnet | "Review this code" | Idioms, concurrency safety, force-unwraps, retain cycles |
| `swiftui-specialist` | Sonnet | SwiftUI view, state, navigation work | State management, view extraction, performance |
| `ios-security-auditor` | Opus | Security review, Keychain, biometrics, ATS | OWASP MASVS-aligned audit |
| `crypto-reviewer` | Opus | Any cryptographic code | Algorithm choice, key management, randomness |
| `ios-test-engineer` | Sonnet | Test writing, coverage, mocks | Swift Testing, snapshots, dependency injection for testability |
| `ios-researcher` | Sonnet | Apple API / WWDC / Swift Evolution questions | Up-to-date framework research with citations |
| `build-doctor` | Sonnet | Build failures, code signing, dependency hell | Diagnose `xcodebuild` errors and fix them |

Invoke explicitly with "Use the `<agent-name>` to …" or let Claude pick automatically based on your prompt.

---

## Hooks: turn suggestions into enforced workflow

| Event | Script | What it enforces |
|---|---|---|
| `SessionStart` | `session-start.sh` | Prints project name, Swift version, branch, simulator state |
| `PreToolUse` (Edit/Write/MultiEdit) | `file-protection.sh` | **Blocks** edits to `.env*`, `*Secrets.*`, `GoogleService-Info.plist`, entitlements, `.git/`, `Podfile.lock`, `.swiftlint.yml`, `.swiftformat`, and more |
| `PreToolUse` (Bash) | `dangerous-commands.sh` | Blocks `rm -rf /`, `git push --force`, destructive resets |
| `PreToolUse` (Bash) | `no-auto-commit.sh` | **Blocks** `git commit`, `git push`, `git tag`, `git merge`, `git rebase`, `git cherry-pick`, `git revert` — you review the diff and commit manually |
| `PostToolUse` (Swift files) | `swift-quality.sh` | Runs SwiftFormat → SwiftLint; error-level violations block until fixed |
| `PostToolUse` (Swift files, opt-in) | `incremental-build.sh` | Triggers background `swift build` for immediate error feedback (Swift packages only) |
| `SessionEnd` | `session-summary.sh` | Appends summary to `.claude/session.log` |

All hooks are shell scripts you can read, modify, or disable. None of them phone home.

---

## MCP connectors (what to plug in)

See [`docs/CONNECTORS.md`](docs/CONNECTORS.md) for full setup. The short list:

| Connector | Why | Install command |
|---|---|---|
| **XcodeBuildMCP** | Builds, tests, simulators, screenshots — 59 tools, maintained by Sentry | `claude mcp add --transport stdio XcodeBuildMCP -- npx -y xcodebuildmcp@latest` |
| **Apple `mcpbridge`** | Native Xcode IDE access (Xcode 26.3+), SwiftUI preview rendering | `xcrun mcpbridge` |
| **sosumi** | Searches Apple developer documentation from inside the session | `claude mcp add --transport stdio sosumi -- npx -y mcp-remote https://sosumi.ai/mcp` |
| **GitHub MCP** | PRs, issues, CI status, code review comments | Via Claude Code settings UI |
| **Filesystem MCP** | Scoped file access for files outside the project | Via Claude Code settings UI |

---

## CLAUDE.md scopes — what goes where

Claude Code merges three CLAUDE.md files in this order of precedence:

```
session flags  >  ./CLAUDE.md (project)  >  ~/.claude/CLAUDE.md (global)
```

| Scope | File | Purpose | Examples |
|---|---|---|---|
| **Global** | `~/.claude/CLAUDE.md` | Your personal iOS-dev brain, every project | Swift 6 by default, MVVM defaults, SwiftLint enforced, no force-unwraps, no `print()` in committed code |
| **Project** | `./CLAUDE.md` | Project-specific rules, shared via git | Min iOS target, module structure, naming conventions, project-specific frameworks |
| **Local** | `./CLAUDE.md.local` or `.claude/settings.local.json` | Personal overrides for this project, gitignored | Your simulator preference, your branch naming, your sandbox tokens |

All three templates are in `templates/`.

---

## Recommended skill packs to layer on top

This repo intentionally **doesn't bundle** other people's skills — install them separately so you get updates:

```bash
# Inside Claude Code
/plugin marketplace add AvdLee/Swift-Concurrency-Agent-Skill
/plugin install swift-concurrency@swift-concurrency-agent-skill

/plugin marketplace add AvdLee/SwiftUI-Agent-Skill
/plugin install swiftui-expert@swiftui-expert-skill

/plugin marketplace add AvdLee/Swift-Testing-Agent-Skill
/plugin install swift-testing-expert@swift-testing-agent-skill

/plugin marketplace add AvdLee/Core-Data-Agent-Skill
/plugin install core-data-expert@core-data-agent-skill

/plugin marketplace add CharlesWiltgen/Axiom
/plugin install axiom@axiom

# For security-sensitive apps (wallets, fintech, healthcare)
/plugin marketplace add trailofbits/skills
```

See [`docs/SKILLS.md`](docs/SKILLS.md) for the full curated list and why each is worth installing.

---

## Documentation

- [`docs/INSTALL.md`](docs/INSTALL.md) — full install walkthrough, troubleshooting
- [`docs/CONNECTORS.md`](docs/CONNECTORS.md) — MCP setup, all five connectors
- [`docs/AGENTS.md`](docs/AGENTS.md) — how to use, customise, and add agents
- [`docs/HOOKS.md`](docs/HOOKS.md) — hook lifecycle, security implications, customisation
- [`docs/CUSTOMIZATION.md`](docs/CUSTOMIZATION.md) — make this yours
- [`docs/SKILLS.md`](docs/SKILLS.md) — curated external skills

---

## Requirements

- **macOS** 13+ (Ventura or later)
- **Xcode** 16+ (Xcode 26.3+ unlocks the native Claude Agent integration)
- **Claude Code** ≥ 2.0 — install from [claude.com/install](https://claude.ai/install.sh)
- **Node.js** 18+ — for XcodeBuildMCP and other npx-based connectors
- **SwiftLint** and **SwiftFormat** (optional but recommended) — `brew install swiftlint swiftformat`

---

## Philosophy

A few principles this repo follows so you know what you're getting:

1. **Generic by default, specific where it matters.** The defaults work for any iOS app; opinionated where opinions reduce ambiguity (Swift 6 strict concurrency, SwiftUI-first, `@Observable`).
2. **Hooks enforce, agents advise.** Linting and dangerous-command guards are non-negotiable; architecture suggestions are advisory.
3. **You commit, Claude doesn't.** Claude is blocked from running `git commit`, `git push`, `git tag`, `git merge`, `git rebase`, `git cherry-pick`, or `git revert`. You review the diff and commit yourself.
4. **No "47 generic agents" bloat.** Eight focused subagents, each with a distinct trigger. More crowds context and confuses the router.
5. **Security on by default.** OWASP MASVS posture, Keychain over UserDefaults, blocked edits to secrets, entitlements, and even SwiftLint config — out of the box.
6. **Plays well with others.** Doesn't bundle AvdLee/Axiom/Trail of Bits skills — points you at them so you get updates from the source.

---

## Contributing

PRs welcome. The simplest contributions:
- New subagent? Drop a `.md` in `plugin/agents/` with frontmatter and a clear trigger description.
- New hook? Shell script in `plugin/hooks/scripts/`, bind it in `plugin/hooks/hooks.json`.
- New command? `.md` in `plugin/commands/` with `description` and `allowed-tools`.

See [`docs/CUSTOMIZATION.md`](docs/CUSTOMIZATION.md) for the patterns.

---

## License

MIT — see [`LICENSE`](LICENSE). Use it, fork it, ship it.

---

## Credits & inspiration

Standing on the shoulders of:
- **Cameron Cooke / Sentry** — [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP)
- **Antoine van der Lee** — [AvdLee skills](https://github.com/AvdLee)
- **Charles Wiltgen** — [Axiom](https://github.com/CharlesWiltgen/Axiom)
- **Trail of Bits** — [security skills](https://github.com/trailofbits/skills)
- **Anthropic** — [official skills](https://github.com/anthropics/skills) and the Claude Code platform
- **keskinonur** & **ApptitudeLabs** — community iOS setup guides whose patterns informed this repo
