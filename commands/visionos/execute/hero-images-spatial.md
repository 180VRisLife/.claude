Create spatial hero content and immersive image experiences for VisionOS, including 3D photo presentations, spatial galleries, and immersive media viewing following the planning documentation:

$ARGUMENTS

**Agent to use:** `@swiftui-spatial-developer`

**Overview:**
You are implementing spatial hero content and immersive image experiences designed specifically for VisionOS, transforming traditional 2D images into compelling spatial presentations, 3D photo galleries, and immersive media experiences that leverage mixed reality capabilities.

**VisionOS Spatial Hero Content Considerations:**

1. **Spatial Image Presentation:**
   - Transform 2D images into spatial 3D presentations
   - Implement depth and parallax effects for visual impact
   - Create immersive photo galleries with spatial navigation
   - Handle high-resolution images efficiently in 3D space

2. **Mixed Reality Integration:**
   - Place hero content appropriately in user's environment
   - Respect physical space constraints and comfort zones
   - Implement natural spatial navigation and interaction
   - Consider lighting and environmental factors

3. **Performance & Quality:**
   - Optimize high-resolution image rendering for VisionOS
   - Implement progressive loading for large image sets
   - Manage memory efficiently with spatial image caching
   - Maintain high visual quality in immersive context

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required hero content types and presentations
   - Image sources, formats, and quality requirements
   - User interaction patterns and navigation needs
   - Integration with existing content management

2. **Study existing patterns** in the codebase:
   - Look for existing image handling and presentation patterns
   - Check for media asset management and caching
   - Review 3D content presentation implementations
   - Identify existing spatial UI components and patterns

3. **Spatial Hero Architecture:**
   - Create modular spatial image presentation components
   - Implement efficient image loading and caching systems
   - Set up 3D transformation and animation frameworks
   - Design spatial navigation and interaction patterns

4. **Core Spatial Image Features:**
   - Create 3D image presentation views with depth effects
   - Implement spatial image galleries with natural navigation
   - Add parallax scrolling and depth-based animations
   - Create immersive image viewing experiences

5. **VisionOS-Specific Presentations:**
   - Design for optimal viewing distance and comfort
   - Implement eye tracking consideration for image focus
   - Create spatial zoom and detail exploration features
   - Add natural hand gesture interactions for navigation

6. **Advanced Spatial Effects:**
   - Implement depth-based image layering and separation
   - Create atmospheric effects and spatial lighting
   - Add particle effects and environmental enhancements
   - Use spatial audio for immersive image storytelling

7. **Gallery & Navigation:**
   - Create spatial photo gallery layouts with 3D arrangement
   - Implement smooth transitions between images
   - Add spatial breadcrumbs and navigation indicators
   - Support both gesture and gaze-based navigation

8. **Image Optimization:**
   - Implement progressive image loading for spatial context
   - Optimize image formats and compression for VisionOS
   - Create efficient texture management for 3D rendering
   - Handle different image aspect ratios in spatial layouts

**Key Files to Create/Modify:**
- `SpatialHeroView.swift` - Main spatial hero content presentation
- `SpatialImageGallery.swift` - 3D photo gallery component
- `ImmersiveImageViewer.swift` - Full immersive image experience
- `SpatialImageEffects.swift` - 3D effects and transformations
- `ImageSpatialCache.swift` - Optimized image caching for spatial content
- `SpatialNavigationManager.swift` - Gallery navigation coordination
- Integration with existing image management and content systems

**Spatial Hero Components:**
- **3D Image Frames:** Floating image presentations with depth
- **Spatial Galleries:** Arranged photo collections in 3D space
- **Immersive Viewers:** Full-environment image experiences
- **Interactive Zoom:** Spatial magnification and detail exploration
- **Depth Layers:** Multi-layered image presentations with parallax

**Visual Effects & Animation:**
- Smooth 3D transformations and positioning
- Parallax effects based on user movement
- Depth-based blur and focus effects
- Atmospheric lighting and environmental integration
- Smooth transitions between spatial states

**Testing Requirements:**
- Test image loading and caching performance
- Verify spatial positioning and comfort across different viewing distances
- Test navigation gestures and eye tracking integration
- Validate high-resolution image quality in immersive context
- Test memory usage and thermal impact

**Performance Optimization:**
- Implement efficient texture streaming for large images
- Use Level-of-Detail (LOD) for distant spatial content
- Optimize 3D rendering performance for image galleries
- Implement smart caching based on spatial proximity
- Consider thermal management for intensive image processing

**User Experience:**
- Design for comfortable viewing distances and angles
- Implement intuitive spatial navigation patterns
- Provide clear visual feedback for interactions
- Support accessibility in spatial image viewing
- Handle motion sensitivity and comfort preferences

**Deliverables:**
- Compelling spatial hero image presentations
- Immersive 3D photo gallery experiences
- Efficient spatial image caching and loading
- Natural gesture-based navigation system
- High-quality spatial visual effects

Before completing, run a build check to ensure no compilation errors in the files you modified.