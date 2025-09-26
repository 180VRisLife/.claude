I want to define a new VisionOS spatial feature, eventually resulting in a `.docs/plans/[feature-name]/requirements.md` file. This requirements document should follow the template in `/Users/chrisjamesbliss/.claude/file-templates/requirements.template.md`. Your job is to ask me a series of questions to help clarify the requirements and implementation details for spatial computing functionality. The feature is medium in scope, so we don't need exhaustive planning or edge-case coverage — just a solid, actionable requirements document.

At a high level, the feature is:

$ARGUMENTS

Focus on:
- **Spatial User Experience**: What the user sees, does, and expects in 3D space — including window positioning, volume interactions, and immersive experiences.
- **VisionOS-Specific Implementation**: How we'll build it using SwiftUI for visionOS, RealityKit entities, ARKit integration, spatial gestures, and eye tracking as needed.
- **Spatial Data & Storage**: CloudKit integration for spatial data, local caching for 3D assets, and SharePlay considerations.
- **Platform Constraints**: VisionOS-specific limitations like memory management, thermal considerations, and mixed reality context.

Start by familiarizing yourself with the feature. Use 1-3 agents (more for complex spatial features) _in parallel_ to investigate the codebase and gather the context you need:

**Recommended agents for VisionOS context gathering:**
- `@swiftui-spatial-developer` - For spatial UI patterns, window management, and volume implementations
- `@realitykit-developer` - For 3D entities, spatial interactions, and immersive experiences
- `@visionos-architect` - For platform-specific patterns, memory management, and system integration

Then, ask me questions to frame the spatial goals, then go deeper into UX and technical details. When it feels like we've covered enough to write a good requirements document, summarize what we have, and ask me if we're ready to write it. The final requirements document should be non-technical, but it should list all the files relevant to the feature at the bottom, so that a developer could quickly familiarize themselves and create a more technical spatial implementation plan.

Important rules for VisionOS features:
- Don't assume spatial behaviors I haven't described — ask instead.
- Consider mixed reality context — how does this work alongside the user's physical environment?
- Account for eye tracking, hand gestures, and spatial audio where relevant.
- Memory and thermal constraints are critical — lightweight implementations preferred.
- Breaking changes are okay — VisionOS is a new platform.
- Be efficient — don't over-plan, but ensure spatial UX is clearly defined.
- If I seem stuck, help me clarify by offering VisionOS-specific examples or spatial tradeoffs.
- Be thorough in your research. Pause questions to use agents if needed — better to be slow and informed than fast and wrong about spatial computing patterns.

Example spatial considerations to explore:
- Window vs. volume vs. immersive space usage
- Spatial anchoring and persistence
- Multi-user SharePlay interactions
- Mixed reality object placement
- Hand tracking vs. eye tracking vs. tap gestures
- Spatial audio integration
- 3D asset optimization and caching