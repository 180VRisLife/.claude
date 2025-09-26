Run comprehensive testing in VisionOS Simulator, including spatial interaction testing, performance validation, and mixed reality experience verification following the planning documentation:

$ARGUMENTS

**Agent to use:** `@visionos-testing-specialist`

**Overview:**
You are conducting comprehensive testing of VisionOS applications using the VisionOS Simulator, focusing on spatial computing functionality, performance characteristics, user experience validation, and mixed reality interaction patterns that are unique to the platform.

**VisionOS Testing Considerations:**

1. **Spatial Functionality Testing:**
   - Test 3D UI components and spatial interactions
   - Verify volume positioning and window management
   - Validate gesture recognition and hand tracking simulation
   - Test eye tracking integration and gaze-based interactions

2. **Mixed Reality Context:**
   - Test app behavior in different immersion levels
   - Verify spatial positioning and comfort zones
   - Test mixed reality object placement and interaction
   - Validate environmental awareness and spatial mapping

3. **Performance & Constraints:**
   - Monitor memory usage and thermal characteristics
   - Test performance with multiple volumes and complex 3D content
   - Verify smooth frame rates and rendering performance
   - Validate efficient resource management

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Specific features and functionality to test
   - Expected user workflows and interaction patterns
   - Performance benchmarks and quality standards
   - Critical user journeys and edge cases

2. **Study existing patterns** in the codebase:
   - Identify key features and components to test
   - Review existing test suites and testing patterns
   - Understand app architecture and integration points
   - Identify performance-critical code paths

3. **VisionOS Simulator Setup:**
   - Configure VisionOS Simulator with appropriate device settings
   - Set up testing environment and debugging tools
   - Configure simulator controls for spatial interaction testing
   - Set up performance monitoring and profiling tools

4. **Comprehensive Test Suite:**
   - Create systematic test plan covering all major features
   - Test spatial UI components and 3D interactions
   - Validate multi-volume functionality and coordination
   - Test real-time features like SharePlay and collaboration

5. **Spatial Interaction Testing:**
   - Test hand gesture recognition and spatial taps
   - Verify eye tracking accuracy and gaze interactions
   - Test spatial navigation and volume transitions
   - Validate 3D object manipulation and positioning

6. **Performance Testing:**
   - Monitor memory usage during intensive operations
   - Test rendering performance with complex 3D content
   - Validate smooth animations and transitions
   - Test thermal behavior under sustained usage

7. **User Experience Validation:**
   - Test comfort and ergonomics of spatial positioning
   - Verify intuitive interaction patterns
   - Test accessibility features in spatial context
   - Validate error handling and edge cases

8. **Integration Testing:**
   - Test external service integrations (analytics, push notifications)
   - Verify network functionality and offline behavior
   - Test authentication flows and user management
   - Validate data persistence and synchronization

**Key Testing Areas:**

**Spatial UI Testing:**
- Window and volume creation, positioning, and management
- 3D UI component rendering and interaction
- Spatial layout and positioning accuracy
- Gesture recognition and response times

**Performance Testing:**
- Memory usage profiling across different app states
- Frame rate monitoring during intensive 3D operations
- CPU and GPU utilization analysis
- Thermal impact assessment

**Feature Integration Testing:**
- StoreKit integration and purchase flows
- Analytics event tracking and data collection
- Push notification delivery and handling
- Cache system efficiency and data integrity

**User Journey Testing:**
- First-time user onboarding and spatial introduction
- Core feature workflows in spatial context
- Multi-user collaboration and SharePlay functionality
- Error recovery and graceful degradation

**Testing Tools & Commands:**
```bash
# Build and run in VisionOS Simulator
xcodebuild -project YourApp.xcodeproj -scheme YourApp -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# Run with performance monitoring
xcrun simctl spawn "Apple Vision Pro" instruments -t "Time Profiler" YourApp.app

# Memory testing
xcrun simctl spawn "Apple Vision Pro" leaks YourApp

# Generate test reports
xcodebuild test -project YourApp.xcodeproj -scheme YourApp -destination 'platform=visionOS Simulator,name=Apple Vision Pro' -resultBundlePath TestResults.xcresult
```

**Test Documentation:**
- Create detailed test execution reports
- Document spatial interaction patterns and behaviors
- Record performance benchmarks and metrics
- Identify issues, bugs, and areas for improvement

**Critical Test Scenarios:**
- Cold app launch and initialization
- Multiple volume creation and management
- Intensive 3D rendering and animation
- Network connectivity changes
- Memory pressure and resource constraints
- User switching and multi-user scenarios

**Testing Deliverables:**
- Comprehensive test execution report
- Performance analysis and benchmarking results
- Bug reports and issue documentation
- Spatial UX validation and recommendations
- Regression test suite for ongoing development

Before completing, ensure all tests pass and document any issues found for developer review.