---
description: Run tests for the current context — unit, UI, or specific target
argument-hint: [target-name | --ui | --coverage]
allowed-tools: mcp__xcodebuildmcp__*, Bash(swift *), Read, Glob
---

# Test

Run tests using XcodeBuildMCP.

## Steps

1. Decide what to test based on `$ARGUMENTS`:
   - No args → run unit tests for the default test target
   - Target name → run that target's tests
   - `--ui` → run UI tests (slow, prefer to invoke explicitly)
   - `--coverage` → enable code coverage, summarise after
2. Use the appropriate tool:
   - Workspace: `mcp__xcodebuildmcp__test_sim_name_ws`
   - Project: `mcp__xcodebuildmcp__test_sim_name_proj`
   - Swift package: `mcp__xcodebuildmcp__swift_package_test`
3. Report:
   - Pass/fail count
   - Failing test names with the first assertion failure
   - For `--coverage`: top 5 lowest-covered files

Do not run UI tests without explicit `--ui` or user confirmation. They are slow and prone to flake.
