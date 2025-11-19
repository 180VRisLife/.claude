# Debugging Workflow for General Development

## Debug Infrastructure

`/init-workspace` automatically sets up Python debug utilities:
- **Git info helper** - `git_info.py` for git state detection
- **Debug logger** - `debug_logger.py` with logging module
- **.env templates** - Development and production environment files
- **Debug patterns guide** - Language-specific debug mode detection patterns

### Available Templates

#### Git Info Helper
- `git_info.py` - Python version producing `[branch@hash]` format

#### Debug Logger
- `debug_logger.py` - Python with logging module, supports categories, DEBUG/RELEASE modes, and file output in debug mode

### Git Info Display Formats

- Normal branch: `[main@a1b2c3d]`
- Detached HEAD: `[@a1b2c3d]`
- Dirty state (uncommitted changes): `[main@a1b2c3d*]`
- Not a git repo: `[unknown]`

### Using Git Info (Python)

```python
from git_info import get_git_info, get_git_components

# Simple string
git_info = get_git_info()
print(git_info)  # [main@a1b2c3d]

# Individual components
components = get_git_components()
print(f"Branch: {components['branch']}")
print(f"Hash: {components['hash']}")
print(f"Dirty: {components['is_dirty']}")
```

### Using Debug Logger (Python)

```python
import os
from debug_logger import logger

# Enable debug mode
os.environ['DEBUG'] = '1'

# Log with categories
logger.log("Application started", 'app')
logger.info("Loading configuration", 'app')
logger.warning("API rate limit approaching", 'network')
logger.error("Failed to connect", 'network')
logger.separator()
```


### Environment Variables

Use `.env.development` and `.env.production` templates:

```bash
# .env.development
DEBUG=1
ENVIRONMENT=development
LOG_LEVEL=debug

# .env.production
DEBUG=0
ENVIRONMENT=production
LOG_LEVEL=info
```

### Debug Mode Detection

Python debug mode detection:
```python
import os

IS_DEBUG = os.getenv('DEBUG', '0') == '1'
# or
IS_DEBUG = os.getenv('ENVIRONMENT', '').lower() == 'development'
```

See `debug-patterns.md` for additional language-specific patterns (TypeScript, Go, Ruby, PHP, etc.) and framework-specific patterns for Flask, Django, Express, Rails, Laravel, and more.

## Debugging Workflow

1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (UI, services, data, integrations) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, async/threading, memory/lifecycle, external dependencies)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, concurrency issues, memory management)
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

Example 1: "App crashes intermittently during data sync"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: Data sync implementation and network handling
  - Agent 2: Local database operations and transactions
  - Agent 3: Background task scheduling and lifecycle

Example 2: "Feature works in development but fails in production"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: Environment configuration and deployment differences hypothesis
  - Agent 2: External dependency and API integration hypothesis
  - Agent 3: Resource constraints and scaling hypothesis

Example 3: "Performance degrades over time"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: Memory management and retain cycles
  - Agent 2: Resource cleanup and lifecycle issues
  - Agent 3: Data accumulation and cache management
