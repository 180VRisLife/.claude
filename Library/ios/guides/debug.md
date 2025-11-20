# Debugging Workflow for iOS Development

## Debug Infrastructure

`/init-workspace` automatically sets up:
- **Separate Debug/Release builds** - Different bundle IDs, app icons, product names
- **Debug app icons** - Generated with red diagonal slash and "DEBUG" text
- **DebugLogger.swift** - File-based logging to `/tmp/{ProjectName}-Debug.log` (DEBUG only)
- **DebugOverlay.swift** - Collapsible debug overlay with version/build/git info
- **GitInfo.swift** - Git state detection displaying `[branch@hash]` format
- **Icon generation script** - `.claude/scripts/generate-debug-icon.py` for updating icons

### Build Configurations

**Debug Build:**
- Bundle ID: `com.company.app.debug`
- Product Name: `AppName-Debug`
- App Icon: `AppIcon-Debug` (with slash overlay)

**Release Build:**
- Bundle ID: `com.company.app`
- Product Name: `AppName`
- App Icon: `AppIcon`

### Git Info Display Formats

- Normal branch: `[main@a1b2c3d]`
- Detached HEAD: `[@a1b2c3d]`
- Dirty state (uncommitted changes): `[main@a1b2c3d*]`
- In worktree: `[feature-branch@a1b2c3d]`

### Updating Debug Icons

After changing your app icon, regenerate debug icons:
```bash
python3 .claude/scripts/generate-debug-icon.py ./ProjectName/Assets.xcassets
```

## Debugging Workflow

1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (UI/SwiftUI, RealityKit, ARKit, spatial anchors, services, data) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, spatial computing/RealityKit, async/threading, memory/lifecycle, external dependencies)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, concurrency issues, memory management, spatial computing issues)
3. **Choose the 3 most likely causes** - Consolidate findings from parallel investigations and prioritize based on probability and impact
4. **Decide whether to implement or debug** - If the cause is obvious, implement the fix and inform the user. If the cause is not obvious, continue this workflow.

Steps for Non-obvious Causes:
5. **Add iterative logging to narrow down the issue**:
   - Start with broad, high-level logging to identify which subsystem/section contains the bug
   - Test and analyze output to determine the rough area
   - Add narrow, targeted logging within that specific section
   - Test again to pinpoint the exact issue
   - Focus on decision points and state changes—avoid overwhelming logs by logging everything
6. **Let the user test** - Have them run the app with the new logging
7. **Fix when solution is found** - Implement the actual fix once root cause is confirmed
8. **Remove all debugging artifacts** - Clean up temporary debugging code:
   - Logging statements: console.log/debug/warn, print(), NSLog, println, debugPrint, os_log (DEBUG-only)
   - Debug flags: DEBUG = true, isDebug = true, isDevelopment = true
   - Code markers: // DEBUG, // TEMP, // REMOVE, // FIXME (debugging context)
   - Test artifacts: Hardcoded test values, mock data, fake API responses
   - Commented debugging code blocks
   - Excessive verbose logging added during development
   - EXCEPTIONS (allowed): Debug UI features (user-facing diagnostic screens) OR release diagnostics infrastructure (like DebugLogger, properly gated for production)

Remember:
- Reading the entire file usually uncovers more information than just a snippet
- Without complete context, edge cases will be missed
- Making assumptions leads to poor analysis—stepping through code and logic sequentially is the best way to find the root cause

Include relevant debugging commands/tools (debugger, profiler, logging) and explain your reasoning for each step.

**Parallel Debugging Examples:**

Example 1: "Spatial anchors drifting over time"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: WorldTrackingProvider and anchor persistence
  - Agent 2: RealityKit entity hierarchy and transform updates
  - Agent 3: Spatial anchor lifecycle and session management

Example 2: "Immersive space not loading correctly"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: ImmersiveSpace lifecycle and scene initialization hypothesis
  - Agent 2: Asset loading and RealityKit resource management hypothesis
  - Agent 3: Permissions and entitlements for spatial features hypothesis

Example 3: "Hand tracking gestures not recognized"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: HandTrackingProvider configuration and chirality
  - Agent 2: Gesture recognition thresholds and timing
  - Agent 3: Coordinate space transforms and entity positioning

Example 4: "Complex feature-specific bug"
→ Combine investigation with specialist knowledge:
  - Agent 1: @code-finder-advanced to understand the implementation
  - Agent 2: @root-cause-analyzer focusing on the bug hypothesis
  - Agent 3: Domain specialist (@shareplay-feature, @backend, etc.) to review against best practices
