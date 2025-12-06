## File Size Guidelines

### Code Files
- **Small files** (<300 lines): Read entire file with Read tool
- **Medium files** (300-800 lines): Read strategically; use offset/limit for specific sections
- **Large files** (800-2000 lines): Use Grep first to find relevant sections, then Read with offset/limit
- **Huge files** (2000+ lines): Anti-pattern; flag for refactoring

**Recommended maximums before refactoring:**
- Views/Components: 200-400 lines; extract subcomponents beyond 600 lines
- Controllers/ViewModels/Managers: 300-600 lines; split responsibilities beyond 1,000 lines
- Models/Types: 100-200 lines; use extensions or partials beyond 400 lines
- Utilities/Helpers: 200-400 lines; split beyond 600 lines
- General modules: 300-500 lines; refactor beyond 800 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A 700-line module managing one cohesive feature is better than three fragmented files with artificial boundaries.

### Token Budget Awareness
Each file read consumes tokens from the context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
