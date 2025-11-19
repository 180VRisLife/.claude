# Effective iOS Implementation Planning Guide

Before creating any plan, conduct thorough investigation—NOTHING can be left to assumptions. Specificity is critical for successful iOS implementation.

A well-structured plan should include:

1. **Summary**
   - Clear, concise description of what functionality will be implemented
   - The core problem being solved or feature being added

2. **Reasoning/Motivation**
   - Why this approach was chosen
   - Trade-offs considered (performance vs simplicity, UIKit vs SwiftUI, flexibility vs complexity)
   - Key decisions made during investigation

3. **Current System Overview**
   - How the existing system works (be specific)
   - Key files and their responsibilities:
     - List actual file paths (e.g., Sources/Services/AuthService.swift, Sources/Views/DashboardView.swift)
     - Describe what each file does in the current implementation
   - Dependencies and data flow
   - iOS version requirements and framework dependencies

4. **New System Design**
   - How the system will work after implementation
   - New or modified files required:
     - List exact file paths that will be created or changed
     - Describe the purpose of each change
   - Integration points with existing code
   - View models, coordinators, or architectural components needed

5. **Other Relevant Context**
   - Utility functions or helpers needed (with file paths)
   - Protocol definitions or model structs (with file paths)
   - Configuration changes required (Info.plist, build settings, entitlements)
   - External dependencies or SPM/CocoaPods packages
   - Testing considerations (unit tests, UI tests)
   - Memory management considerations (retain cycles, weak references)
   - Threading requirements (@MainActor, background queues)

**What NOT to include in plans:**
- Code snippets or implementation details
- Timelines or effort estimates
- Self-evident advice for iOS developers
- Generic best practices
- Vague descriptions without file references

**Critical Requirements:**
- Every assertion must be based on actual investigation, not assumptions
- All file references must be exact paths discovered during research
- Dependencies between components must be explicitly mapped
- Edge cases and constraints must be identified through code analysis
- iOS framework APIs and their availability must be verified

Remember: A plan fails when it makes assumptions about behavior. Investigate thoroughly, reference specifically, plan comprehensively.
