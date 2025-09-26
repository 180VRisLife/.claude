Create spatial splash screens and app launch experiences for VisionOS, including immersive loading sequences, 3D brand elements, and spatial onboarding flows following the planning documentation:

$ARGUMENTS

**Agent to use:** `@swiftui-spatial-developer`

**Overview:**
You are implementing spatial splash screens and launch experiences specifically designed for VisionOS, leveraging 3D space, immersive environments, and spatial brand presentation to create compelling app introduction sequences that feel native to mixed reality computing.

**VisionOS Splash Screen Considerations:**

1. **Spatial Brand Experience:**
   - Create 3D logo presentations and brand elements
   - Design immersive loading sequences in spatial context
   - Implement progressive app initialization with spatial feedback
   - Consider user's physical environment during launch

2. **Mixed Reality Context:**
   - Handle launch in different immersion levels (windowed vs. immersive)
   - Respect user's physical space during splash presentation
   - Implement comfortable spatial positioning for brand elements
   - Consider eye tracking and natural user attention patterns

3. **Performance & Thermal:**
   - Optimize splash screen performance for quick app startup
   - Minimize 3D asset complexity during launch
   - Implement progressive loading to avoid thermal issues
   - Use efficient animation and rendering techniques

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required splash screen content and branding
   - App initialization sequence and loading requirements
   - User onboarding flow integration
   - Brand guidelines and visual identity

2. **Study existing patterns** in the codebase:
   - Look for existing launch and initialization patterns
   - Check for brand assets and visual identity elements
   - Review app lifecycle and state management
   - Identify existing 3D assets and spatial components

3. **Spatial Splash Architecture:**
   - Create modular splash screen components
   - Implement progressive loading and initialization
   - Set up spatial positioning and animation systems
   - Handle different launch contexts (cold start, warm start, etc.)

4. **Core Splash Implementation:**
   - Design spatial logo presentation with 3D elements
   - Create immersive loading indicators and progress displays
   - Implement smooth transitions from splash to main app
   - Add spatial audio elements for brand experience

5. **VisionOS-Specific Features:**
   - Implement spatial positioning for optimal viewing comfort
   - Create 3D brand elements using RealityKit
   - Add eye tracking consideration for logo placement
   - Design for different immersion modes and contexts

6. **Progressive Loading:**
   - Show immediate brand presence while loading app resources
   - Implement staged loading with visual feedback
   - Preload critical app components during splash
   - Handle loading failures and error states gracefully

7. **Spatial Animations:**
   - Create smooth 3D logo animations and reveals
   - Implement spatial particle effects and brand elements
   - Add depth and dimensionality to loading indicators
   - Use spatial audio cues for loading progression

8. **Onboarding Integration:**
   - Transition seamlessly from splash to onboarding
   - Prepare user context for spatial app experience
   - Handle first launch vs. returning user scenarios
   - Set up user preferences and spatial settings

**Key Files to Create/Modify:**
- `SpatialSplashView.swift` - Main spatial splash screen
- `SpatialLogo.swift` - 3D logo component with RealityKit
- `LoadingProgressView.swift` - Spatial loading indicators
- `OnboardingCoordinator.swift` - Launch to onboarding transition
- `LaunchManager.swift` - App initialization coordination
- `BrandAssets.swift` - 3D brand elements and materials
- Integration with app lifecycle and initialization

**Spatial Splash Components:**
- **3D Logo Presentation:** Animated brand logo in spatial context
- **Immersive Loading:** Progress indicators with depth and animation
- **Environmental Setup:** Spatial environment preparation for app
- **Brand Storytelling:** Brief immersive brand experience sequences
- **User Preparation:** Spatial orientation and comfort setup

**Animation & Effects:**
- Smooth 3D logo reveals and transformations
- Particle effects and atmospheric elements
- Spatial depth animations and parallax effects
- Progressive opacity and material changes
- Spatial audio synchronization with visual elements

**Testing Requirements:**
- Test splash screen performance in VisionOS Simulator
- Verify spatial positioning and comfort across different users
- Test loading progression and timing
- Validate transitions to main app experience
- Test different launch scenarios and error handling

**Performance Optimization:**
- Minimize initial 3D asset complexity
- Use efficient animation techniques
- Implement progressive asset loading
- Optimize for quick startup and low memory usage
- Consider thermal impact of 3D rendering

**Brand Integration:**
- Implement brand guidelines in spatial context
- Create consistent visual identity in 3D space
- Use brand colors, typography, and elements effectively
- Maintain brand recognition in immersive environment

**Deliverables:**
- Compelling spatial splash screen experience
- 3D brand logo and visual elements
- Progressive loading with spatial feedback
- Smooth transitions to main app experience
- Optimized performance for VisionOS launch

Before completing, run a build check to ensure no compilation errors in the files you modified.