Implement SharePlay integration for VisionOS app, enabling synchronized spatial experiences, multi-user collaboration, and shared immersive content following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-shareplay-developer`

**Overview:**
You are implementing comprehensive SharePlay functionality for a VisionOS application, including synchronized spatial experiences, multi-user collaboration in 3D space, shared immersive content, and coordinated mixed reality interactions.

**VisionOS SharePlay Considerations:**

1. **Spatial Collaboration:**
   - Synchronize 3D object positions and transformations across users
   - Share spatial anchor data and world tracking information
   - Coordinate multiple users in shared virtual spaces
   - Handle spatial audio for multi-user experiences

2. **Mixed Reality Coordination:**
   - Synchronize mixed reality object placement
   - Share spatial mapping and environment data (privacy-compliant)
   - Coordinate physical space interactions
   - Handle different user environments and capabilities

3. **VisionOS-Specific Challenges:**
   - Manage different immersion levels across participants
   - Handle user presence and attention in spatial context
   - Synchronize gesture and interaction events
   - Coordinate window and volume positioning

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required SharePlay activities and experiences
   - Multi-user interaction patterns and requirements
   - Content sharing and synchronization needs
   - Integration with existing app features

2. **Study existing patterns** in the codebase:
   - Look for existing networking and communication patterns
   - Check for real-time data synchronization implementations
   - Review user management and state handling
   - Identify 3D content and spatial interaction patterns

3. **SharePlay Framework Integration:**
   - Set up GroupActivities framework
   - Create activity types for different shared experiences
   - Implement GroupSession management
   - Handle SharePlay lifecycle and state changes

4. **Core SharePlay Implementation:**
   - Create `SharePlayManager` singleton
   - Implement activity creation and joining flows
   - Set up participant management and coordination
   - Handle session synchronization and messaging

5. **VisionOS-Specific SharePlay Features:**
   - Implement spatial synchronization for 3D objects
   - Share spatial anchor data between participants
   - Coordinate immersive experience transitions
   - Synchronize gesture and interaction events

6. **Real-time Communication:**
   - Implement reliable message passing between participants
   - Set up real-time state synchronization
   - Handle network latency and connection issues
   - Implement conflict resolution for concurrent changes

7. **Spatial Coordination:**
   - Synchronize 3D object positions and orientations
   - Share spatial positioning and movement data
   - Coordinate multi-user gesture interactions
   - Handle spatial audio positioning for participants

8. **User Experience:**
   - Create spatial UI for SharePlay invitation and management
   - Implement participant presence indicators
   - Add spatial avatars or user representations
   - Handle user joining/leaving gracefully

**Key Files to Create/Modify:**
- `SharePlayManager.swift` - Main SharePlay coordinator
- `SpatialActivity.swift` - Custom GroupActivity definitions
- `SharePlaySession.swift` - Session management and coordination
- `SpatialSynchronizer.swift` - 3D content synchronization
- `ParticipantManager.swift` - User presence and management
- `SharePlayUI.swift` - Spatial SharePlay interface components
- Integration with existing 3D content and user management

**SharePlay Activities to Implement:**
- **Collaborative Viewing:** Shared media and content consumption
- **Spatial Collaboration:** Joint 3D object manipulation and creation
- **Immersive Experiences:** Synchronized VR/AR experiences
- **Multi-user Games:** Spatial gaming and interactive experiences
- **Presentation Mode:** Shared presentations and demonstrations

**Synchronization Features:**
- Real-time 3D object position sync
- Shared spatial anchor management
- Coordinated gesture and interaction events
- Synchronized media playback and timing
- User presence and attention tracking

**Testing Requirements:**
- Test SharePlay invitation and joining flows
- Verify spatial synchronization between multiple simulators
- Test real-time messaging and state sync
- Validate handling of network issues and reconnection
- Test participant management and graceful degradation

**Performance Considerations:**
- Optimize network usage for spatial data
- Implement efficient synchronization algorithms
- Handle low latency requirements for real-time interaction
- Manage memory usage with multiple participants
- Consider thermal impact of continuous networking

**Privacy & Security:**
- Handle spatial data privacy appropriately
- Implement secure communication between participants
- Respect user privacy in shared experiences
- Comply with SharePlay privacy guidelines

**Deliverables:**
- Complete SharePlay framework integration
- VisionOS-optimized spatial collaboration features
- Real-time synchronization system
- Multi-user spatial experience coordination
- Comprehensive participant management

Before completing, run a build check to ensure no compilation errors in the files you modified.