Configure Pushwoosh push notification system for VisionOS app, including spatial notification handling and mixed reality context awareness following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-pushwoosh-developer`

**Overview:**
You are implementing comprehensive Pushwoosh push notification integration for a VisionOS application, including traditional push notifications adapted for spatial computing context, spatial notification UI, and mixed reality notification handling.

**VisionOS Push Notification Considerations:**

1. **Spatial Notification UI:**
   - Design notification presentations that work in 3D space
   - Consider user's current immersion level (windowed vs. immersive)
   - Implement non-intrusive spatial notification placement
   - Handle notifications during mixed reality experiences

2. **Mixed Reality Context:**
   - Respect user's current activity and immersion state
   - Provide spatial audio cues for notifications
   - Handle notifications during SharePlay sessions
   - Consider physical environment context

3. **VisionOS Permissions:**
   - Handle notification permissions in spatial context
   - Integrate with VisionOS system notification settings
   - Respect user's notification preferences per app mode

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required notification types and content
   - User segmentation and targeting needs
   - Integration with existing user management
   - Analytics and tracking requirements

2. **Study existing patterns** in the codebase:
   - Look for existing notification implementations
   - Check for user authentication and identification patterns
   - Review analytics integration points
   - Identify app lifecycle and state management

3. **Pushwoosh SDK Integration:**
   - Add Pushwoosh SDK dependency to the project
   - Configure Pushwoosh app ID and API token
   - Set up proper initialization and configuration
   - Handle development vs. production environments

4. **Core Push Notification Implementation:**
   - Create `PushNotificationManager` singleton
   - Implement device registration and token management
   - Handle notification permissions and user consent
   - Set up notification delegate and response handling

5. **VisionOS-Specific Notification Handling:**
   - Implement spatial notification UI components
   - Handle notifications in different app states (windowed, volumetric, immersive)
   - Add spatial audio notification cues
   - Manage notifications during SharePlay sessions
   - Implement contextual notification suppression

6. **User Segmentation & Targeting:**
   - Set up user tags and custom data fields
   - Implement user behavior tracking for targeting
   - Configure geolocation services (if applicable)
   - Set up A/B testing for notification content

7. **Rich Notification Features:**
   - Implement rich media notifications
   - Add interactive notification actions
   - Handle deep linking from notifications
   - Implement notification categories and templates

8. **Analytics Integration:**
   - Track notification delivery and open rates
   - Monitor user engagement with notifications
   - Implement custom conversion tracking
   - Integrate with existing analytics systems

**Key Files to Create/Modify:**
- `PushNotificationManager.swift` - Main Pushwoosh manager
- `NotificationDelegate.swift` - Notification handling delegate
- `SpatialNotificationView.swift` - VisionOS notification UI
- `NotificationPermissions.swift` - Permission management
- App delegate integration for notification lifecycle
- Integration with existing user management and analytics

**VisionOS-Specific Features:**
- Spatial notification positioning and layout
- Immersion-aware notification handling
- Mixed reality context sensitivity
- SharePlay notification coordination
- Spatial audio notification cues
- Hand gesture notification interactions

**Testing Requirements:**
- Test notification registration and delivery
- Verify spatial notification UI in different app modes
- Test permission flow in VisionOS Simulator
- Validate deep linking and notification actions
- Test notification handling during immersive experiences

**Security Considerations:**
- Handle notification data privacy appropriately
- Implement proper token refresh and validation
- Secure sensitive notification content
- Comply with VisionOS privacy guidelines

**Deliverables:**
- Complete Pushwoosh SDK integration
- VisionOS-optimized notification UI
- Spatial notification handling system
- User segmentation and targeting setup
- Analytics integration for notification metrics

Before completing, run a build check to ensure no compilation errors in the files you modified.