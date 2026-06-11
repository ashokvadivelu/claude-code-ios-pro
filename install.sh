#!/usr/bin/env bash
#
# install.sh — claude-code-ios-pro installer
#
# Two paths, both interactive:
#   1. Plugin install (recommended) — adds the marketplace, you run /plugin install in Claude Code.
#   2. Direct install — copies agents/commands/hooks/skills into ~/.claude/ and wires up hooks
#      in ~/.claude/settings.json so they actually fire.
#
# Either way, backs up any existing files to ~/.claude/backup-<timestamp>/.
#

set -euo pipefail

# ---- styling ---------------------------------------------------------------
BOLD=$(tput bold 2>/dev/null || echo "")
DIM=$(tput dim 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")

say()   { printf "%s\n" "$1"; }
ok()    { printf "${GREEN}✓${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}⚠${RESET}  %s\n" "$1"; }
err()   { printf "${RED}✗${RESET} %s\n" "$1" >&2; }
ask()   { read -r -p "$(printf "${BOLD}?${RESET} %s [y/N] " "$1")" reply; [[ "$reply" =~ ^[Yy]$ ]]; }

# ---- banner ----------------------------------------------------------------
cat <<EOF

${BOLD}claude-code-ios-pro installer${RESET}
${DIM}Production-grade Claude Code setup for senior iOS developers.${RESET}

EOF

# ---- preflight -------------------------------------------------------------
say "${BOLD}Preflight checks${RESET}"

if [[ "$OSTYPE" != "darwin"* ]]; then
    err "This setup targets macOS. Detected: $OSTYPE"
    exit 1
fi
ok "macOS detected"

if ! command -v claude &> /dev/null; then
    err "Claude Code CLI not found. Install: curl -fsSL https://claude.ai/install.sh | bash"
    exit 1
fi
ok "Claude Code CLI: $(claude --version 2>/dev/null | head -1 || echo 'installed')"

command -v xcodebuild &> /dev/null && ok "Xcode: $(xcodebuild -version | head -1)" || warn "xcodebuild not on PATH"
command -v swift       &> /dev/null && ok "Swift: $(swift --version | head -1)"     || warn "swift not on PATH"
command -v jq          &> /dev/null && ok "jq installed"          || warn "jq missing — hooks need it: brew install jq"
command -v swiftlint   &> /dev/null && ok "SwiftLint installed"   || warn "SwiftLint missing — install: brew install swiftlint"
command -v swiftformat &> /dev/null && ok "SwiftFormat installed" || warn "SwiftFormat missing — install: brew install swiftformat"
command -v python3     &> /dev/null && ok "python3 available (for settings merge)" || { err "python3 required"; exit 1; }

echo

# ---- locate this repo ------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
REPO_URL="${CLAUDE_IOS_PRO_REPO:-https://github.com/<your-username>/claude-code-ios-pro}"
WORK_DIR=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/.claude-plugin/marketplace.json" ]; then
    WORK_DIR="$SCRIPT_DIR"
    ok "Installing from local clone: $WORK_DIR"
else
    WORK_DIR=$(mktemp -d)
    say "Cloning $REPO_URL into $WORK_DIR…"
    git clone --depth 1 "$REPO_URL" "$WORK_DIR" || { err "Clone failed"; exit 1; }
    ok "Cloned"
fi

echo
say "${BOLD}Choose install method:${RESET}"
say "  1) ${BOLD}Plugin${RESET} (recommended) — auto-updates, single source of truth, hooks bundled"
say "  2) ${BOLD}Direct${RESET} (file copy) — full control, copies files into ~/.claude/, no auto-update"
say "  3) ${BOLD}Both${RESET} — plugin + global CLAUDE.md template"
echo
read -r -p "$(printf "${BOLD}?${RESET} [1/2/3] ")" INSTALL_METHOD
INSTALL_METHOD=${INSTALL_METHOD:-1}

# ---- backup existing ~/.claude --------------------------------------------
CLAUDE_HOME="$HOME/.claude"
BACKUP_DIR="$CLAUDE_HOME/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CLAUDE_HOME"

# ---- install CLAUDE.md (all methods) --------------------------------------
if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    if ask "Overwrite ~/.claude/CLAUDE.md? (existing will be backed up)"; then
        mkdir -p "$BACKUP_DIR"
        cp "$CLAUDE_HOME/CLAUDE.md" "$BACKUP_DIR/CLAUDE.md"
        cp "$WORK_DIR/templates/home/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
        ok "Installed ~/.claude/CLAUDE.md (old backed up)"
    fi
else
    cp "$WORK_DIR/templates/home/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
    ok "Installed ~/.claude/CLAUDE.md"
fi

# ---- install settings.json (all methods) ----------------------------------
if [ -f "$CLAUDE_HOME/settings.json" ]; then
    if ask "Overwrite ~/.claude/settings.json?"; then
        mkdir -p "$BACKUP_DIR"
        cp "$CLAUDE_HOME/settings.json" "$BACKUP_DIR/settings.json"
        cp "$WORK_DIR/templates/home/settings.json" "$CLAUDE_HOME/settings.json"
        ok "Installed ~/.claude/settings.json (old backed up)"
    fi
else
    cp "$WORK_DIR/templates/home/settings.json" "$CLAUDE_HOME/settings.json"
    ok "Installed ~/.claude/settings.json"
fi

# ---- plugin install (methods 1, 3) ----------------------------------------
if [ "$INSTALL_METHOD" = "1" ] || [ "$INSTALL_METHOD" = "3" ]; then
    echo
    say "${BOLD}Adding the plugin marketplace${RESET}"
    say "(then run ${BOLD}/plugin install ios-dev-pro@claude-code-ios-pro${RESET} from inside Claude Code)"

    REPO_SLUG=$(echo "$REPO_URL" | sed -E 's|.*github\.com/||; s|\.git$||')
    if claude plugin marketplace add "$REPO_SLUG" 2>/dev/null; then
        ok "Marketplace added: $REPO_SLUG"
    else
        warn "Could not add marketplace automatically. Run manually inside Claude Code:"
        warn "  /plugin marketplace add $REPO_SLUG"
    fi
fi

# ---- direct install (methods 2, 3) ----------------------------------------
if [ "$INSTALL_METHOD" = "2" ] || [ "$INSTALL_METHOD" = "3" ]; then
    echo
    say "${BOLD}Direct install — copying files into ~/.claude/${RESET}"

    mkdir -p "$CLAUDE_HOME"/{agents,commands,hooks,skills}

    # Agents
    for f in "$WORK_DIR/plugin/agents/"*.md; do
        name=$(basename "$f")
        [ -f "$CLAUDE_HOME/agents/$name" ] && { mkdir -p "$BACKUP_DIR"; cp "$CLAUDE_HOME/agents/$name" "$BACKUP_DIR/agents-$name"; }
        cp "$f" "$CLAUDE_HOME/agents/$name"
    done
    ok "Agents: $(ls "$CLAUDE_HOME/agents/" | wc -l | xargs)"

    # Commands
    for f in "$WORK_DIR/plugin/commands/"*.md; do
        name=$(basename "$f")
        [ -f "$CLAUDE_HOME/commands/$name" ] && { mkdir -p "$BACKUP_DIR"; cp "$CLAUDE_HOME/commands/$name" "$BACKUP_DIR/commands-$name"; }
        cp "$f" "$CLAUDE_HOME/commands/$name"
    done
    ok "Commands: $(ls "$CLAUDE_HOME/commands/" | wc -l | xargs)"

    # Hooks
    for f in "$WORK_DIR/plugin/hooks/scripts/"*.sh; do
        name=$(basename "$f")
        cp "$f" "$CLAUDE_HOME/hooks/$name"
        chmod +x "$CLAUDE_HOME/hooks/$name"
    done
    ok "Hook scripts: $(ls "$CLAUDE_HOME/hooks/" | wc -l | xargs)"

    # Skills
    for d in "$WORK_DIR/plugin/skills/"*/; do
        skillname=$(basename "$d")
        mkdir -p "$CLAUDE_HOME/skills/$skillname"
        cp -R "$d"* "$CLAUDE_HOME/skills/$skillname/"
    done
    ok "Skills: $(ls -d "$CLAUDE_HOME/skills/"*/ 2>/dev/null | wc -l | xargs)"

    # Wire up hooks in settings.json. The plugin's hooks.json uses
    # ${CLAUDE_PLUGIN_ROOT} which doesn't apply here, so we substitute $HOME.
    echo
    say "Wiring hook bindings into ~/.claude/settings.json…"
    python3 - "$CLAUDE_HOME/settings.json" "$HOME" << 'PYEOF'
import json, sys
path, home = sys.argv[1], sys.argv[2]
h = f"{home}/.claude/hooks"
with open(path) as r: cfg = json.load(r)
cfg["hooks"] = {
    "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": f"{h}/session-start.sh"}]}],
    "PreToolUse": [
        {"matcher": "Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": f"{h}/file-protection.sh"}]},
        {"matcher": "Bash", "hooks": [
            {"type": "command", "command": f"{h}/dangerous-commands.sh"},
            {"type": "command", "command": f"{h}/no-auto-commit.sh"}
        ]}
    ],
    "PostToolUse": [
        {"matcher": "Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": f"{h}/swift-quality.sh"}]}
    ],
    "SessionEnd": [{"matcher": "", "hooks": [{"type": "command", "command": f"{h}/session-summary.sh"}]}]
}
with open(path, "w") as w:
    json.dump(cfg, w, indent=2)
    w.write("\n")
print("✓ Hook bindings written")
PYEOF
fi

# ---- optional: install MCP servers ----------------------------------------
echo
say "${BOLD}MCP connectors (optional)${RESET}"

if ask "Install XcodeBuildMCP? (essential — builds, tests, simulators)"; then
    claude mcp add --transport stdio XcodeBuildMCP -- npx -y xcodebuildmcp@latest \
        && ok "XcodeBuildMCP installed" || warn "XcodeBuildMCP install failed"
fi

if ask "Install sosumi (Apple developer docs MCP via the hosted proxy)?"; then
    claude mcp add --transport stdio sosumi -- npx -y mcp-remote https://sosumi.ai/mcp \
        && ok "sosumi installed" || warn "sosumi install failed"
fi

if xcrun --find mcpbridge &> /dev/null 2>&1; then
    if ask "Install Apple xcrun mcpbridge? (Xcode 26.3+)"; then
        claude mcp add --transport stdio AppleMCPBridge -- xcrun mcpbridge \
            && ok "Apple mcpbridge installed" || warn "mcpbridge install failed"
    fi
fi

# ---- done ------------------------------------------------------------------
echo
cat <<EOF

${GREEN}${BOLD}✓ Done.${RESET}

${BOLD}Next steps:${RESET}
EOF

if [ "$INSTALL_METHOD" = "1" ] || [ "$INSTALL_METHOD" = "3" ]; then
cat <<EOF
  1. Launch Claude Code: ${BOLD}claude${RESET}
  2. Install the plugin:  ${BOLD}/plugin install ios-dev-pro@claude-code-ios-pro${RESET}
  3. Verify hooks fire:   ${BOLD}/agents${RESET} should show 8 agents; try editing a Swift file
EOF
fi

if [ "$INSTALL_METHOD" = "2" ]; then
cat <<EOF
  1. Launch Claude Code: ${BOLD}claude${RESET}
  2. Verify install:     ${BOLD}/agents${RESET} should show 8 agents
  3. Test the hook:      edit a Swift file — the swift-quality hook should run SwiftLint
EOF
fi

cat <<EOF

${DIM}For per-project setup (CLAUDE.md, .mcp.json), see: $WORK_DIR/templates/project/${RESET}
${DIM}Backup directory: $BACKUP_DIR${RESET}

EOF
