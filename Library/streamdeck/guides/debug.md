# Debugging Workflow for Streamdeck Development

1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (plugin actions, property inspector UI, WebSocket communication, integrations) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, WebSocket communication, Stream Deck SDK integration, action manifest, external API integration)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, WebSocket issues, manifest configuration, external service integration)
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

Example 1: "Action not responding to key press"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: Action event handlers and keyDown/keyUp lifecycle
  - Agent 2: WebSocket message handling and event registration
  - Agent 3: Plugin manifest and action UUID configuration

Example 2: "Property Inspector not updating action settings"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: Property Inspector HTML/JS and sendToPlugin messages hypothesis
  - Agent 2: Plugin action settings persistence and didReceiveSettings hypothesis
  - Agent 3: WebSocket connection state and message routing hypothesis

Example 3: "Plugin works locally but fails after distribution"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: File paths and resource bundling
  - Agent 2: Manifest validation and Stream Deck version compatibility
  - Agent 3: Code signing and distribution packaging
