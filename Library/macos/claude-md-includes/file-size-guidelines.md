## File Size Guidelines

### Swift Code Files
- **Views (SwiftUI/AppKit)**: 100-200 lines; extract subviews beyond 300 lines
- **ViewModels/Managers**: 200-300 lines; split responsibilities beyond 500 lines
- **Models**: 50-100 lines; use extensions for computed properties beyond 200 lines
- **Utilities/Extensions**: 100-200 lines; split beyond 300 lines

### File Reading Strategy
- **<200 lines**: Read entire file with Read tool
- **200-500 lines**: Read with offset/limit for targeted sections
- **500-2000 lines**: Use Grep first, then Read specific sections
- **>2000 lines**: Flag for refactoring

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
