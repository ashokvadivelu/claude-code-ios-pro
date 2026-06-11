---
description: Build, install, and launch the app on a booted simulator with log streaming
allowed-tools: mcp__xcodebuildmcp__*, Bash
---

# Run

Boot a simulator, build and install the app, launch it, stream logs.

## Steps

1. List booted simulators with `mcp__xcodebuildmcp__list_sims`. If none booted, boot the default (`iPhone 16 Pro` unless overridden by `DEFAULT_SIMULATOR`).
2. Build for that simulator (delegate to `/build`-style detection of workspace vs project).
3. Install the resulting `.app` with `mcp__xcodebuildmcp__install_app_sim`.
4. Launch it with `mcp__xcodebuildmcp__launch_app_sim` and capture the bundle identifier.
5. Begin log capture via `mcp__xcodebuildmcp__start_sim_log_cap`, filtered to the app's subsystem.
6. Report:
   - Simulator name + UDID
   - App bundle ID
   - Log capture session ID (so the user can `stop_sim_log_cap` later)

Don't tail logs forever — start the capture and hand control back to the user.
