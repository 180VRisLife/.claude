# MCP Tools

MCP (Model Context Protocol) servers extend Claude with specialized capabilities. These tools are triggered automatically when relevant, or explicitly via commands.

## Installed MCPs

### context7

Fetches up-to-date documentation for any library (npm, pip, crates, etc.).

**Automatic triggers:**

- Questions about library APIs
- "How do I use X in [library]?"
- Requests for current documentation

### apple-docs

Searches Apple Developer Documentation, WWDC content, and sample code.

**Automatic triggers:**

- Questions about Apple frameworks (SwiftUI, UIKit, etc.)
- iOS/macOS/visionOS development queries
- Requests for Apple API references

**Additional capabilities:**

- `list_technologies` - Browse all Apple frameworks
- `search_framework_symbols` - Find symbols within a framework
- `get_sample_code` - Browse complete sample projects
- `search_wwdc_content` - Search WWDC video transcripts
- `get_wwdc_video` - Access full session content with code examples

## Triggering Behavior

| Mode | Description |
|------|-------------|
| **Automatic** | Claude uses MCPs when queries match their domain |
| **Direct request** | "Use context7 to look up..." or "Search Apple docs for..." |

## When to Request Explicitly

Ask Claude to use MCP tools when you want to:

- Guarantee fresh documentation (not from Claude's training data)
- Force a lookup even for topics Claude might know
- Get the most current API references
