## File Size Guidelines

### Swift Code Files
- **Views (SwiftUI/RealityKit)**: 200-400 lines; extract subviews beyond 600 lines
- **ViewModels/Managers**: 300-600 lines; split responsibilities beyond 1,000 lines
- **Models**: 100-200 lines; use extensions for computed properties beyond 400 lines
- **Utilities/Extensions**: 200-400 lines; split beyond 600 lines

**Key principle:** Prefer logical coherence over arbitrary limits. A 700-line ViewModel managing one cohesive feature is better than three fragmented files with artificial boundaries.

### File Reading Strategy
- **<300 lines**: Read entire file with Read tool
- **300-800 lines**: Read strategically; use offset/limit for targeted sections
- **800-2000 lines**: Use Grep first, then Read specific sections
- **>2000 lines**: Flag for refactoring

### Token Budget Awareness
Each file read consumes tokens from the 1M context window. Prefer targeted reads (Grep + offset/limit) for large files to preserve context capacity for actual implementation work.
