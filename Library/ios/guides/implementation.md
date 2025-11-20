# iOS Implementation Best Practices

## Before You Begin: Agent Selection

For complex implementations, consider using specialized agents:

**Feature Development**:
- @ui-swiftui - SwiftUI views, components, screens
- @networking-data - Networking, data persistence, API integration
- @architecture-coordinator - App architecture, coordinators, navigation

**Investigation First**:
- @code-finder - Locate existing patterns to follow
- @code-finder-advanced - Understand complex architectural relationships

**Task Execution**:
- @implementor - Execute well-defined tasks from plans

For simple changes (1-4 files), implement directly. For complex features, deploy appropriate specialist agents.

## Implementation Best Practices

Before implementing iOS features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established architectural patterns (MVVM, Coordinators, etc.)
   - Maintain consistency with existing SwiftUI/UIKit code style
   - Reuse existing view components, utilities, and services

2. **iOS-Specific Security**
   - Validate and sanitize ALL user inputs
   - Use Keychain for sensitive data storage (never UserDefaults)
   - Implement proper App Transport Security (ATS) configurations
   - Handle authentication tokens securely
   - Respect user privacy with proper permission requests
   - Use parameterized queries for Core Data/SQL operations

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully with proper Swift error handling
   - Provide meaningful user-facing error messages
   - Consider edge cases (empty states, nil values, data not loaded)
   - Add defensive nil-checking and guard statements
   - Implement proper logging for debugging (os_log, but remove debug logs before commit)

4. **iOS Testing Strategy**
   - Write unit tests for ViewModels and business logic
   - Add UI tests for critical user flows using XCTest
   - Test on multiple device sizes and orientations
   - Test error conditions and edge cases
   - Ensure tests are maintainable and readable

5. **Code Quality**
   - Write clean, readable, self-documenting Swift code
   - Use meaningful variable and function names
   - Keep functions/methods focused and single-purpose
   - Follow Swift API design guidelines
   - Avoid retain cycles (use weak/unowned references appropriately)
   - Use @MainActor appropriately for UI updates

6. **Performance Considerations**
   - Avoid blocking the main thread (use async/await, Task)
   - Use appropriate data structures and algorithms
   - Implement lazy loading for heavy resources
   - Profile with Instruments for performance bottlenecks
   - Optimize image loading and caching

7. **iOS Accessibility**
   - Add proper accessibility labels and hints
   - Support Dynamic Type for text scaling
   - Ensure VoiceOver compatibility
   - Maintain sufficient color contrast
   - Support keyboard navigation and assistive technologies

8. **Documentation**
   - Document public APIs with Swift doc comments (///)
   - Explain complex logic or non-obvious SwiftUI behaviors
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable components

9. **iOS-Specific Considerations**
   - Check iOS version availability for new APIs (@available)
   - Handle app lifecycle events properly
   - Manage memory carefully (avoid retain cycles)
   - Test on actual devices, not just simulator
   - Consider battery and network impact

Remember: iOS implementation is not just about making it work—it's about making it work reliably, securely, performantly, and in a way that respects iOS platform conventions.
