---
description: Build the iOS project intelligently — detects workspace/project, scheme, simulator
allowed-tools: mcp__xcodebuildmcp__*, Bash(swift *), Read, Glob
---

# Build

Build the current iOS project. Use XcodeBuildMCP — never raw `xcodebuild` from the shell.

## Steps

1. Detect what's in the current directory:
   - `*.xcworkspace` → use `mcp__xcodebuildmcp__build_sim_name_ws`
   - `*.xcodeproj` → use `mcp__xcodebuildmcp__build_sim_name_proj`
   - `Package.swift` only → use `mcp__xcodebuildmcp__swift_package_build`
2. If multiple schemes exist, list them with `mcp__xcodebuildmcp__list_schems` and ask which.
3. Default simulator: read `DEFAULT_SIMULATOR` from settings env, fall back to "iPhone 16 Pro".
4. Build. Report success or surface only the first error with file:line.

If the build fails with an opaque error, suggest invoking the `build-doctor` agent.
