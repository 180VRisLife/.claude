Set up domain-specific infrastructure for the workspace.

**Note:** Base agents, workflow commands, guides, and hooks are now global (in `~/.claude/`). This command sets up domain-specific infrastructure.

**Usage:**
- `/0-workspace` - Auto-detect domain from codebase
- `/0-workspace <domain>` - Use specified domain

**Available domains:**
- **ios**: iOS apps (Swift, UIKit/SwiftUI)
- **macos**: macOS apps (Swift, AppKit/SwiftUI)
- **visionos**: visionOS apps (Swift, RealityKit/SwiftUI)
- **webdev**: React/Next.js web applications
- **streamdeck**: Stream Deck plugins
- **default**: General development (Python preferred)

**If domain is provided:** Use it directly.

**If domain is not provided:** Auto-detect based on:
- **ios**: Xcode project with UIKit
- **macos**: Xcode project with AppKit
- **visionos**: Xcode project with RealityKit
- **webdev**: Next.js config or React in package.json
- **streamdeck**: @elgato/streamdeck in package.json
- **default**: Everything else

**Steps:**

1. **Run the initialization script:**
```bash
python3 ~/.claude/scripts/init-workspace.py <domain>
```

2. **Add file size guidelines to local CLAUDE.md:**
After the script completes, use the Task tool to add file size guidelines:
- Read `~/.claude/includes/file-size-guidelines.md`
- Find or create `./CLAUDE.md`
- Insert the guidelines in an appropriate location
- Keep content as-is from the reference file

3. **For default domain only - Optimize .gitignore:**
Launch an agent to trim `.gitignore` to relevant languages:
- Detect languages by checking for: `*.py`, `package.json`, `go.mod`, `Cargo.toml`, etc.
- Keep universal sections (Environment, IDE, OS, Logs)
- Remove language-specific sections that don't apply

**Report to user:**
1. Domain selected (with justification if auto-detected)
2. Infrastructure installed:
   - **Swift domains**: DebugOverlay.swift, GitInfo.swift, DebugLogger.swift
   - **webdev**: DebugOverlay.tsx, useGitInfo.ts, logger.ts
   - **streamdeck**: DebugLogger.ts, gitInfo.ts
   - **default**: debug_logger.py, git_info.py
3. .gitignore setup (patterns merged)
4. .worktrees/ directory created
5. File size guidelines added to CLAUDE.md
