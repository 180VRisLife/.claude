# Implementation Plan: [FEATURE]

**Date**: [DATE] | **Spec**: [link]

## Summary

[Primary requirement + technical approach from research]

## Technical Context

<!-- Replace with actual project details. Use "NEEDS CLARIFICATION" for unknowns. -->
<!-- If other features in .spec/ already have a blueprint.md, reference their
Technical Context for consistency. Only document deviations or additions here. -->

**Language/Version**: [e.g., Python 3.11, Swift 5.9]
**Primary Dependencies**: [e.g., FastAPI, UIKit]
**Storage**: [e.g., PostgreSQL, CoreData, N/A]
**Testing**: [e.g., pytest, XCTest]
**Target Platform**: [e.g., Linux server, iOS 15+]
**Project Type**: [single/web/mobile]
**Performance Goals**: [e.g., 1000 req/s, 60 fps]
**Constraints**: [e.g., <200ms p95, offline-capable]
**Scale/Scope**: [e.g., 10k users, 50 screens]

## Project Structure

### Documentation (this feature)

```text
.spec/[###-feature]/
├── blueprint.md         # /blueprint output
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1
└── tasks.md             # /tasks output
```

### Source Code

<!-- Keep ONLY the matching option. Expand with real paths. -->

```text
# Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/
tests/
├── contract/
├── integration/
└── unit/

# Web application (frontend + backend)
backend/src/{models,services,api}/ + tests/
frontend/src/{components,pages,services}/ + tests/

# Mobile + API (iOS/Android)
api/ + ios/ or android/ (platform-specific structure)
```

**Structure Decision**: [Selected structure and rationale]

## Complexity Tracking

> Fill ONLY if there are violations that must be justified.

| Violation           | Why Needed | Simpler Alternative Rejected Because |
| ------------------- | ---------- | ------------------------------------ |
| [e.g., 4th project] | [reason]   | [why simpler insufficient]           |
