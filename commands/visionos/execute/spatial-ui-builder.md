Build spatial UI components with windows and volumes for VisionOS, following the planning documentation:

$ARGUMENTS

**Agent to use:** `@swiftui-spatial-developer`

**Overview:**
You are implementing spatial UI components that leverage VisionOS's unique windowing system, supporting traditional windows, 3D volumes, and immersive spaces. This includes proper spatial layout, gesture handling, and integration with the visionOS window management system.

**Key VisionOS Spatial UI Patterns:**

1. **Window Types:**
   - `.window()` - Traditional 2D windows in 3D space
   - `.volumetric()` - 3D volumes for spatial content
   - `.immersiveSpace()` - Full immersive experiences

2. **Spatial Layout:**
   - Use `RealityView` for 3D content integration
   - Implement proper spatial margins and positioning
   - Consider user's physical environment and comfort zones

3. **Gesture Integration:**
   - Hand tracking with `.onTapGesture()` for spatial interactions
   - Eye tracking integration where appropriate
   - Spatial drag and pinch gestures for 3D manipulation

4. **Performance Considerations:**
   - Optimize for thermal management
   - Implement efficient 3D asset loading
   - Use spatial anchoring wisely to avoid overhead

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Specific UI components needed
   - Spatial interaction patterns required
   - Integration points with existing code

2. **Study existing spatial patterns** in the codebase:
   - Look for existing VisionOS views and modifiers
   - Identify reusable spatial components
   - Check for established window management patterns

3. **Implement spatial UI components:**
   - Create or enhance SwiftUI views for VisionOS
   - Add proper spatial modifiers and positioning
   - Integrate RealityKit entities where needed
   - Implement gesture recognizers for spatial interactions

4. **Window Management:**
   - Configure appropriate window styles (`.window`, `.volumetric`, `.immersiveSpace`)
   - Set proper spatial bounds and positioning
   - Handle window state management and transitions

5. **Spatial UX Patterns:**
   - Implement comfortable viewing distances
   - Add spatial feedback (haptics, audio cues)
   - Ensure accessibility in spatial context
   - Test for motion sickness considerations

**Files to Focus On:**
- SwiftUI view files (typically in Views/ directories)
- App configuration for window scenes
- Reality entities and spatial components
- Gesture handlers and spatial interactions

**Testing Requirements:**
- Build and test in VisionOS Simulator
- Verify spatial positioning and comfort
- Test gesture recognition and interactions
- Validate performance with thermal considerations

**Deliverables:**
- Functional spatial UI components
- Proper window/volume configuration
- Gesture integration for spatial interactions
- Documentation of spatial UX patterns implemented

Before completing, run a build check to ensure no compilation errors in the files you modified.