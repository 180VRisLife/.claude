Set up Amplitude analytics integration for VisionOS app, including spatial interaction tracking and mixed reality event collection following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-analytics-developer`

**Overview:**
You are implementing comprehensive Amplitude analytics for a VisionOS application, including standard app analytics plus spatial computing specific events like hand tracking interactions, eye tracking events, spatial positioning, and mixed reality context awareness.

**VisionOS Analytics Considerations:**

1. **Spatial Interaction Events:**
   - Hand gesture tracking (tap, pinch, drag in 3D space)
   - Eye tracking interactions (gaze duration, focus areas)
   - Spatial positioning and movement patterns
   - Window and volume interaction analytics

2. **Mixed Reality Context:**
   - Environment detection and spatial mapping events
   - Object placement and spatial anchoring
   - Multi-user SharePlay session analytics
   - Immersive vs. windowed mode usage patterns

3. **Privacy & Permissions:**
   - Handle spatial data privacy appropriately
   - Respect eye tracking and hand tracking permissions
   - Anonymize spatial positioning data
   - Comply with App Store privacy guidelines

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required analytics events and properties
   - User journey tracking needs
   - Performance and engagement metrics
   - Integration with existing user management

2. **Study existing patterns** in the codebase:
   - Look for existing analytics implementations
   - Check for user identification patterns
   - Review logging and debugging patterns
   - Identify key user interaction points

3. **Amplitude SDK Integration:**
   - Add Amplitude SDK dependency to the project
   - Configure Amplitude API keys and settings
   - Set up proper initialization and configuration
   - Implement user identification and properties

4. **Core Analytics Implementation:**
   - Create `AnalyticsManager` singleton
   - Implement event tracking methods
   - Add user property management
   - Set up session tracking and management

5. **VisionOS-Specific Event Tracking:**
   - Spatial gesture events (hand tracking)
   - Eye tracking interaction events
   - Window/volume management events
   - Immersive space transitions
   - Spatial positioning and movement analytics

6. **Standard App Analytics:**
   - App launch and lifecycle events
   - Feature usage and engagement metrics
   - Error tracking and crash analytics
   - Performance monitoring events
   - User flow and conversion tracking

7. **Privacy-First Implementation:**
   - Implement proper consent management
   - Anonymize personally identifiable information
   - Handle spatial data privacy appropriately
   - Provide analytics opt-out functionality

8. **Performance Optimization:**
   - Implement event batching and queuing
   - Add offline event storage
   - Optimize for VisionOS memory constraints
   - Implement proper error handling

**Key Files to Create/Modify:**
- `AnalyticsManager.swift` - Main analytics manager
- `AnalyticsEvent.swift` - Event types and properties
- `SpatialAnalytics.swift` - VisionOS-specific tracking
- `PrivacyManager.swift` - Analytics consent management
- Integration with existing app lifecycle and user management
- SwiftUI view modifiers for automatic event tracking

**VisionOS-Specific Events to Track:**
- Spatial gesture interactions
- Eye tracking engagement metrics
- Window positioning and resizing
- Volume manipulation events
- Immersive space usage
- SharePlay session participation
- Mixed reality object interactions
- Spatial audio engagement

**Testing Requirements:**
- Verify events are properly sent to Amplitude
- Test spatial interaction tracking in simulator
- Validate user identification and properties
- Test offline event queuing and retry logic
- Verify privacy compliance and opt-out functionality

**Deliverables:**
- Complete Amplitude SDK integration
- VisionOS-specific spatial analytics
- Privacy-compliant event tracking
- Comprehensive user journey analytics
- Performance-optimized implementation

Before completing, run a build check to ensure no compilation errors in the files you modified.