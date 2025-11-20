# Visionos Implementation Best Practices

## Before You Begin: Agent Selection

For complex implementations, consider using specialized agents:

**Feature Development**:
- @expert-visionos-26-feature - visionOS 2.6+ features
- @shareplay-feature - SharePlay integration and collaboration
- @volumetric-layouts-feature - Volumetric content and 3D layouts
- @native-video-playback-feature - AVKit video playback
- @storekit-feature - StoreKit and in-app purchases
- See `.claude/agents/specialist/` for complete roster

**Investigation First**:
- @code-finder - Locate existing patterns to follow
- @code-finder-advanced - Understand complex architectural relationships

**Task Execution**:
- @implementor - Execute well-defined tasks from plans

For simple changes (1-4 files), implement directly. For complex features, deploy appropriate specialist agents.

## Implementation Best Practices

Before implementing visionOS features, ensure you follow these critical practices:

1. **Understand Existing Patterns**
   - Search for similar implementations in the codebase first
   - Follow established spatial computing patterns and conventions
   - Maintain consistency with existing SwiftUI/RealityKit code style
   - Reuse existing entities, components, systems, and utilities

2. **visionOS-Specific Security**
   - Validate and sanitize ALL user inputs
   - Use Keychain for sensitive data storage
   - Handle spatial permissions properly (WorldSensingProvider, HandTrackingProvider)
   - Respect user privacy with proper spatial data handling
   - Implement proper authentication for shared experiences
   - Use parameterized queries for database operations

3. **Error Handling & Edge Cases**
   - Handle all error conditions gracefully with proper Swift error handling
   - Provide meaningful user-facing error messages in spatial UI
   - Consider edge cases (tracking loss, anchor drift, hand occlusion)
   - Add defensive nil-checking and guard statements
   - Implement proper logging for debugging (os_log, but remove debug logs before commit)

4. **visionOS Testing Strategy**
   - Write unit tests for ViewModels and business logic
   - Test spatial interactions in visionOS Simulator
   - Test on actual Vision Pro hardware (simulator has limitations)
   - Test error conditions and spatial edge cases
   - Verify hand tracking, eye tracking, and spatial anchor behavior

5. **Code Quality**
   - Write clean, readable, self-documenting Swift code
   - Use meaningful variable and function names
   - Keep functions/methods focused and single-purpose
   - Follow Swift API design guidelines
   - Avoid retain cycles (use weak/unowned references appropriately)
   - Use @MainActor appropriately for UI updates

6. **Performance Considerations**
   - Avoid blocking the main thread (use async/await, Task)
   - Optimize RealityKit rendering performance (entity count, materials, LOD)
   - Implement efficient spatial queries and raycasting
   - Profile with Instruments for performance bottlenecks
   - Consider battery impact and thermal constraints

7. **visionOS Accessibility**
   - Add proper accessibility labels for spatial UI elements
   - Support VoiceOver in immersive spaces
   - Ensure spatial interactions work for users with varying abilities
   - Provide alternatives to hand gestures where appropriate
   - Maintain sufficient visual contrast in spatial UI

8. **Documentation**
   - Document public APIs with Swift doc comments (///)
   - Explain complex spatial logic or RealityKit entity hierarchies
   - Update relevant documentation if behavior changes
   - Include usage examples for reusable spatial components

9. **visionOS-Specific Considerations**
   - Check visionOS version availability for new APIs (@available)
   - Handle ImmersiveSpace lifecycle properly
   - Manage spatial anchor persistence and updates
   - Consider shared space vs. immersive space appropriately
   - Test SharePlay integration if implementing collaborative features
   - Handle coordinate space transforms correctly
   - Optimize for different viewing distances and user comfort

Remember: visionOS implementation is not just about making it work—it's about creating comfortable, performant, and delightful spatial computing experiences that respect platform conventions.
