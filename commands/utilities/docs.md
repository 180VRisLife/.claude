# /docs - Smart Documentation Lookup & Generation

Unified documentation command with auto-detection, local-first lookup, and structured output generation.

**Usage:**
- `/docs SwiftUI List` - Auto-detect platform, quick lookup
- `/docs --feature SwiftUI NavigationStack` - Generate `.docs/features/` file
- `/docs --project iOS app with Core Data and CloudKit` - Generate `.docs/` project bundle
- `/docs --apple Core Animation` - Force Apple MCP
- `/docs --context7 react hooks` - Force Context7 MCP

**Query:** $ARGUMENTS

---

## Phase 1: Parse Arguments

Extract from the query:

**Flags:**
- `--feature` → Generate single file to `.docs/features/`
- `--project` → Generate multi-file bundle to `.docs/`
- `--apple` → Force Apple MCP (apple-docs)
- `--context7` → Force Context7 MCP
- No flags → Quick lookup (no file generation)

---

## Phase 2: Platform Detection

If no force flag, auto-detect from query keywords:

**Apple Indicators** (use `mcp__apple-docs__*`):
- Keywords: SwiftUI, UIKit, AppKit, RealityKit, ARKit, Core Data, CloudKit, StoreKit, visionOS, iOS, macOS, watchOS, tvOS
- Frameworks: AVFoundation, Combine, Foundation (Apple context), Metal, SpriteKit, SceneKit, HealthKit, MapKit
- API prefixes: NS*, UI*, SK*, AV*, CL*, MK*, WK*, HK*

**General Indicators** (use `mcp__context7__*`):
- Keywords: React, Next.js, Node, Express, Vue, Angular, Django, FastAPI, Prisma, Tailwind, Supabase
- Patterns: npm packages, Python libraries, JavaScript/TypeScript frameworks

**Both** (launch parallel agents):
- Cross-platform projects: "iOS app with Supabase", "React Native with native modules"
- Generic terms without clear platform: "authentication", "networking", "database"

---

## Phase 3: Local-First Lookup

**Before any external lookups, search for existing documentation:**

1. Check `.docs/` and `.docs/features/` for relevant files
2. Use Glob to find matching documentation: `*.llm-ref.md`, `*.md`
3. If found, present options:

```
Found existing documentation:
- .docs/swiftui-ref.md (SwiftUI reference)
- .docs/features/navigation-stack.llm-ref.md

Options:
[1] Use local docs (no external fetch)
[2] Fetch fresh docs (update local)
[3] Both (compare and merge)
```

---

## Phase 4: Fetch & Generate

### Quick Lookup (no flags)

**For Apple:**
1. `mcp__apple-docs__search_apple_docs` - Find documentation
2. `mcp__apple-docs__get_apple_doc_content` - Get detailed content
3. Present results inline with key info, examples, platform availability

**For Context7:**
1. `mcp__context7__resolve-library-id` - Resolve library
2. `mcp__context7__get-library-docs` - Fetch docs (mode='code' for APIs)
3. Present results inline with signatures, examples, gotchas

### Feature Docs (`--feature`)

1. Determine platform and fetch from appropriate MCP(s)
2. Compress documentation to LLM-optimized format:
   - INCLUDE: Non-obvious signatures, constraints, gotchas, platform availability
   - EXCLUDE: Basic patterns, obvious usage, what Claude knows
3. Write to `.docs/features/{feature-name}.llm-ref.md`
4. Use template from `docs-llm-ref.template.md`

### Project Docs (`--project`)

1. Parse description for technology stack
2. Identify API clusters (e.g., "SwiftUI Views", "Core Data", "Networking")
3. Fetch and compress documentation for each cluster in parallel
4. Generate files:
   - `.docs/index.md` - Inventory + gap analysis
   - `.docs/{cluster-1}.llm-ref.md`
   - `.docs/{cluster-2}.llm-ref.md`
   - (3-5 files total based on complexity)
5. Use templates from `docs-llm-ref.template.md` and `docs-index.template.md`

---

## Phase 5: Gap Detection

After generating documentation, analyze for missing coverage:

1. Review what was documented vs what the project/feature likely needs
2. Identify gaps:
   ```
   Documentation Analysis:
   ✅ Covered: SwiftUI views, Core Data models, Navigation
   ⚠️ Partial: CloudKit sync (basic only)
   ❌ Missing: Error handling patterns, Testing utilities
   ```
3. Suggest next steps:
   ```
   Suggestions:
   - Run `/docs --feature CloudKit advanced sync` for detailed sync docs
   - Consider creating `.docs/patterns/error-handling.md` for conventions
   ```
4. Ask before creating additional docs:
   ```
   Should I create documentation for the missing areas?
   [Yes, create all] [Let me choose] [Skip for now]
   ```

---

## Examples

```
/docs SwiftUI List
→ Auto-detect Apple, quick lookup, present inline

/docs --feature Core Data CloudKit sync
→ Fetch from Apple MCP, compress, write to .docs/features/core-data-cloudkit-sync.llm-ref.md

/docs --project iOS app using SwiftUI, Core Data, and CloudKit
→ Generate .docs/index.md + 3-4 cluster files

/docs --context7 prisma migrations
→ Force Context7, fetch Prisma migration docs

/docs --apple Metal shader compilation
→ Force Apple MCP for Metal docs
```

---

## Output Paths

| Mode | Output Location |
|------|-----------------|
| Quick lookup | Inline (no files created) |
| `--feature` | `.docs/features/{feature-name}.llm-ref.md` |
| `--project` | `.docs/` directory with index + cluster files |
