## File Size Guidelines

### Code Files
- **Small files** (<300 lines): Read entire file with Read tool
- **Medium files** (300-800 lines): Read strategically; use offset/limit for specific sections
- **Large files** (800-2000 lines): Use Grep first to find relevant sections, then Read with offset/limit
- **Huge files** (2000+ lines): Anti-pattern; flag for refactoring

**Recommended maximums before refactoring:**
- General components/modules: 300-500 lines; refactor beyond 800 lines
- Utilities/helpers: 200-400 lines; split beyond 600 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A cohesive 700-line module is better than three fragmented 250-line files.

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
