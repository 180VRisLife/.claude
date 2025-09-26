Implement multiple window volumes and advanced window management for VisionOS, including coordinated multi-volume experiences, spatial window orchestration, and cross-volume data sharing following the planning documentation:

$ARGUMENTS

**Agent to use:** `@swiftui-spatial-developer`

**Overview:**
You are implementing advanced window management for VisionOS that supports multiple volumes, coordinated multi-window experiences, and sophisticated spatial window orchestration. This includes creating systems for managing multiple 3D volumes, coordinating content between windows, and providing seamless cross-volume user experiences.

**VisionOS Multiple Volume Considerations:**

1. **Volume Coordination:**
   - Manage multiple 3D volumes simultaneously
   - Coordinate content and state between different volumes
   - Handle volume positioning and spatial relationships
   - Implement communication channels between volumes

2. **Spatial Window Management:**
   - Optimize volume placement for user comfort and workflow
   - Handle volume lifecycle (creation, positioning, destruction)
   - Manage volume focus and user attention across multiple spaces
   - Implement volume persistence and restoration

3. **Performance & Resources:**
   - Efficiently manage resources across multiple volumes
   - Optimize rendering performance with multiple 3D contexts
   - Handle memory constraints with multiple spatial environments
   - Implement smart volume activation and deactivation

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required multi-volume workflows and use cases
   - Volume types and content requirements
   - Cross-volume interaction patterns and data sharing
   - User experience flow across multiple spatial contexts

2. **Study existing patterns** in the codebase:
   - Look for existing window and scene management patterns
   - Check for state management and data sharing implementations
   - Review existing VisionOS window configuration and usage
   - Identify spatial UI patterns and volume-specific components

3. **Multi-Volume Architecture:**
   - Create `VolumeManager` for coordinating multiple volumes
   - Implement volume registry and lifecycle management
   - Set up inter-volume communication and state synchronization
   - Design volume positioning and spatial relationship management

4. **Core Volume Management:**
   - Implement volume creation and configuration systems
   - Create volume templates for different content types
   - Add volume positioning and spatial arrangement logic
   - Handle volume focus management and user attention

5. **VisionOS-Specific Features:**
   - Configure multiple `.volumetric()` window scenes
   - Implement spatial volume positioning and relationships
   - Create seamless transitions between volumes
   - Add natural multi-volume navigation patterns

6. **Inter-Volume Communication:**
   - Implement data sharing between volumes
   - Create messaging systems for volume coordination
   - Handle state synchronization across multiple spatial contexts
   - Support real-time updates and notifications between volumes

7. **Volume Types & Templates:**
   - Create different volume configurations for various content types
   - Implement specialized volumes (media, productivity, social, etc.)
   - Add volume customization and user preference systems
   - Support dynamic volume creation based on content

8. **User Experience Orchestration:**
   - Design intuitive multi-volume workflows
   - Implement volume switching and focus management
   - Create spatial breadcrumbs and navigation aids
   - Handle volume arrangement and organization patterns

**Key Files to Create/Modify:**
- `VolumeManager.swift` - Central volume coordination system
- `VolumeConfiguration.swift` - Volume setup and template definitions
- `InterVolumeMessaging.swift` - Communication between volumes
- `SpatialVolumeView.swift` - Base volume view components
- `VolumeCoordinator.swift` - Cross-volume state management
- `VolumeRegistry.swift` - Volume tracking and lifecycle
- App scene configuration for multiple volumetric windows
- Integration with existing app architecture and data flow

**Multi-Volume Patterns:**
- **Primary + Auxiliary:** Main volume with supporting detail volumes
- **Dashboard Layout:** Multiple coordinated information volumes
- **Workflow Spaces:** Sequential volumes for complex tasks
- **Collaborative Volumes:** Shared volumes for multi-user experiences
- **Media Galleries:** Coordinated media presentation across volumes

**Volume Coordination Features:**
- Synchronized data updates across volumes
- Cross-volume drag and drop functionality
- Coordinated animation and transition effects
- Shared spatial audio and environmental settings
- Unified user preferences and settings management

**Testing Requirements:**
- Test multiple volume creation and management
- Verify inter-volume communication and data sharing
- Test volume positioning and spatial relationships
- Validate performance with multiple active volumes
- Test user workflows across multiple spatial contexts

**Performance Optimization:**
- Implement smart volume activation/deactivation based on user focus
- Optimize 3D rendering across multiple volumes
- Use efficient memory management for multiple spatial contexts
- Implement Level-of-Detail (LOD) for non-focused volumes
- Monitor thermal impact and adjust volume complexity accordingly

**Spatial UX Patterns:**
- Intuitive volume arrangement and positioning
- Clear visual indicators for volume relationships
- Natural navigation between volumes using gestures and gaze
- Comfortable spatial distances and viewing angles
- Accessibility support across multiple spatial contexts

**Data Management:**
- Efficient state synchronization between volumes
- Shared data models and view models
- Conflict resolution for concurrent volume updates
- Persistent volume configurations and user arrangements

**Deliverables:**
- Comprehensive multi-volume management system
- Inter-volume communication and data sharing
- Spatial volume positioning and coordination
- User-friendly multi-volume workflow experiences
- Performance-optimized volume resource management

Before completing, run a build check to ensure no compilation errors in the files you modified.