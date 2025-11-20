# Debugging Workflow for Webdev Development

## Debug Infrastructure

`/init-workspace` automatically sets up:
- **DebugOverlay.tsx** - React component showing version/build/git info
- **useGitInfo.ts** - React hook for accessing git information
- **logger.ts** - Structured logging utility with categories
- **.env templates** - Development and production environment files
- **inject-git-info.js** - Build-time git info injection script
- **generate-debug-favicon.py** - Debug favicon generator

### Development vs Production Builds

**Development Build (`next dev`):**
- `NODE_ENV=development`
- Debug overlay visible (bottom-right corner)
- Verbose logging to console
- Git info displayed in UI
- Debug favicon with red dot indicator

**Production Build (`next build`):**
- `NODE_ENV=production`
- Debug overlay hidden
- Minimal logging (warnings/errors only)
- Standard favicon

### Git Info Display Formats

- Normal branch: `[main@a1b2c3d]`
- Detached HEAD: `[@a1b2c3d]`
- Unknown (not git repo): `[unknown]`

### Using Debug Overlay

Add to your root layout (`app/layout.tsx`):

```tsx
import { DebugOverlay } from '@/components/DebugOverlay';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <DebugOverlay />
      </body>
    </html>
  );
}
```

### Using Git Info Hook

```tsx
import { useGitInfo } from '@/hooks/useGitInfo';

function MyComponent() {
  const gitInfo = useGitInfo();

  if (!gitInfo) return null; // Production

  return <div>Git: {gitInfo.displayString}</div>;
}
```

### Using Logger

```typescript
import { logger } from '@/lib/logger';

// Development only
logger.debug('User action', 'ui', { action: 'click', target: 'button' });
logger.info('API request started', 'api', { endpoint: '/users' });

// All environments
logger.warn('API rate limit approaching', 'network');
logger.error('Failed to fetch data', 'api', error);
```

### Injecting Git Info

Add to your `package.json` scripts:

```json
{
  "scripts": {
    "dev": "node .claude/scripts/inject-git-info.js .env.development.local && next dev",
    "build": "node .claude/scripts/inject-git-info.js .env.production.local && next build"
  }
}
```

This automatically injects `NEXT_PUBLIC_GIT_BRANCH`, `NEXT_PUBLIC_GIT_HASH`, and `NEXT_PUBLIC_BUILD_TIME`.

### Generating Debug Favicon

```bash
python3 .claude/scripts/generate-debug-favicon.py ./public --style dot
```

Styles: `dot` (red dot), `badge` (DEV badge), `slash` (diagonal slash)

Update `app/layout.tsx` to use conditional favicon:

```tsx
const faviconPath = process.env.NODE_ENV === 'development'
  ? '/favicon-dev.png'
  : '/favicon.png';

return (
  <html>
    <head>
      <link rel="icon" href={faviconPath} />
    </head>
    {/* ... */}
  </html>
);
```

## Debugging Workflow

1. **Understand the codebase** - Read relevant files/entities/assets to understand the codebase, and look up documentation for frameworks and libraries.
   - For simple searches: Use direct tools (Read/Grep/Glob)
   - For quick code location: Use @code-finder agent
   - For complex bugs: Deploy PARALLEL @code-finder-advanced agents (in SINGLE function_calls block)
     - Split by subsystems (frontend/React, backend/API, database, state management) OR
     - Multiple agents investigating the same area from different angles
     - Lean towards parallel unless the bug is very simple
   - For systematic diagnosis: Use @root-cause-analyzer agent
2. **Identify 5-8 most likely root causes** - For non-obvious bugs, deploy PARALLEL @root-cause-analyzer agents (in SINGLE function_calls block)
   - Each agent focuses on different hypothesis categories (state management, async/promises, API integration, rendering/re-renders, external dependencies)
   - Multiple agents can review the same bug from different investigation angles
   - Default to parallel investigation unless bug is trivial
   - List potential reasons for the issue (logic errors, state management, concurrency issues, memory leaks, API/network issues)
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

Example 1: "Component re-rendering infinitely"
→ Deploy 3 parallel @code-finder-advanced agents investigating different subsystems:
  - Agent 1: React component lifecycle and useEffect dependencies
  - Agent 2: State management and Redux/Context updates
  - Agent 3: Props flow and parent component triggers

Example 2: "API requests failing in production but working locally"
→ Deploy 2-3 parallel @root-cause-analyzer agents reviewing the same bug from different angles:
  - Agent 1: CORS configuration and environment variables hypothesis
  - Agent 2: Authentication and API key management hypothesis
  - Agent 3: Network proxies and load balancer configuration hypothesis

Example 3: "Page load performance degrading"
→ Deploy 3 parallel @root-cause-analyzer agents on different hypothesis categories:
  - Agent 1: Bundle size and code splitting optimization
  - Agent 2: API request waterfalls and data fetching strategy
  - Agent 3: Memory leaks and event listener cleanup

Example 4: "Complex feature-specific bug"
→ Combine investigation with specialist knowledge:
  - Agent 1: @code-finder-advanced to understand the implementation
  - Agent 2: @root-cause-analyzer focusing on the bug hypothesis
  - Agent 3: Domain specialist (@shareplay-feature, @backend, etc.) to review against best practices
