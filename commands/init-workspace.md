Set up the workspace with domain-specific configuration.

**Usage:**
- `/init-workspace` - Auto-detect domain from codebase
- `/init-workspace <domain>` - Use specified domain (ios, macos, visionos, webdev, or default)

**Available domains:**
- **ios**: For iOS apps (Swift, Xcode, UIKit, SwiftUI for iPhone/iPad)
- **macos**: For macOS apps (Swift, Xcode, AppKit, SwiftUI for Mac)
- **visionos**: For Apple Vision Pro/visionOS projects (Swift, Xcode, RealityKit, SwiftUI)
- **webdev**: For React/Next.js web applications (modern web frameworks, TypeScript, Tailwind)
- **default**: For general software development (strongly prefers Python; use Go, Node.js, Rust, Java, etc. only if more relevant)

**If domain is provided:** Use it directly without analysis.

**If domain is not provided:** Review the codebase structure and key files to determine the appropriate domain:
- Choose **ios** if: Xcode project with Swift files using UIKit/SwiftUI for iPhone/iPad
- Choose **macos** if: Xcode project with Swift files using AppKit/SwiftUI for Mac
- Choose **visionos** if: Xcode project with Swift files using RealityKit/ARKit/SwiftUI for Vision Pro
- Choose **webdev** if: Next.js config or React-based web application with modern tooling
- Choose **default** if: General programming language project or unclear domain

**After determining the domain, execute these steps:**

1. **Run the initialization script:**
```bash
python3 ~/.claude/scripts/init-workspace.py <domain>
```
Replace `<domain>` with: `ios`, `macos`, `visionos`, `webdev`, or `default`

2. **Enhance the local CLAUDE.md with file size guidelines:**
After the script completes successfully, use the Task tool to launch an agent that will add domain-specific file size guidelines to the project's CLAUDE.md file. The agent should:
- Read `~/.claude/library/<domain>/claude-md-includes/file-size-guidelines.md` for the content to add
- Read the newly created `.claude/CLAUDE.md` or `./CLAUDE.md` file
- Find an appropriate location (near the end, before or after development notes)
- Insert the file size guidelines content from the reference file
- Use non-deterministic placement that fits the existing structure
- Keep the content as-is from the reference file (no modifications)

**Inform the user of:**
1. Which domain was selected and why (1-2 sentence justification if auto-detected)
2. Confirmation that initialization succeeded, including:
   - Number of agents, commands, file templates, guides, hooks, and output styles installed
   - Comprehensive `.gitignore` setup (domain-specific patterns merged with existing entries)
   - Worktree infrastructure setup (`.worktrees/` directory)
   - **For default domain:** Python debug infrastructure created (`utils/git_info.py`, `utils/debug_logger.py`, environment templates)
   - **For other domains:** Any domain-specific infrastructure that was set up
3. Confirmation that file size guidelines were added to CLAUDE.md (and where they were placed)