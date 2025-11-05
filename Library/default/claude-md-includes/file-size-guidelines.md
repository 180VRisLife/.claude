## File Size Guidelines

### Code Files
- **Small files** (<200 lines): Read entire file with Read tool
- **Medium files** (200-500 lines): Read strategically; use offset/limit for specific sections
- **Large files** (500-2000 lines): Use Grep first to find relevant sections, then Read with offset/limit
- **Huge files** (2000+ lines): Anti-pattern; flag for refactoring

**Recommended maximums before refactoring:**
- General components/modules: 200-300 lines; refactor beyond 400 lines
- Utilities/helpers: 100-200 lines; split beyond 300 lines

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
