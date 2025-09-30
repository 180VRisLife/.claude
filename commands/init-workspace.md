Set up the workspace with domain-specific configuration.

**Usage:**
- `/init-workspace` - Auto-detect domain from codebase
- `/init-workspace <domain>` - Use specified domain (visionos, webdev, or default)

**Available domains:**
- **visionos**: For Apple Vision Pro/visionOS projects (Swift, Xcode, RealityKit, SwiftUI)
- **webdev**: For React/Next.js web applications (modern web frameworks, TypeScript, Tailwind)
- **default**: For general software development (Python, Node.js, Go, Rust, Java, etc.)

**If domain is provided:** Use it directly without analysis.

**If domain is not provided:** Review the codebase structure and key files to determine the appropriate domain:
- Choose **visionos** if: Xcode project with Swift files using RealityKit/ARKit/SwiftUI
- Choose **webdev** if: Next.js config or React-based web application with modern tooling
- Choose **default** if: General programming language project or unclear domain

**After determining the domain, execute:**

```bash
python3 ~/.claude/scripts/init-workspace.py <domain>
```

Replace `<domain>` with: `visionos`, `webdev`, or `default`

**Inform the user of:**
1. Which domain was selected and why (1-2 sentence justification if auto-detected)
2. Confirmation that initialization succeeded