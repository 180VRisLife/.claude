//
//  [WINDOW_NAME].swift
//  [PROJECT_NAME]
//
//  Created by [AUTHOR] on [DATE].
//
//  [DESCRIPTION]
//

import SwiftUI
import RealityKit
import RealityKitContent

/// [WINDOW_DESCRIPTION]
///
/// This volumetric window provides:
/// - [FEATURE_1]
/// - [FEATURE_2]
/// - [FEATURE_3]
///
/// Usage:
/// ```swift
/// WindowGroup("[WINDOW_TITLE]", id: "[WINDOW_ID]") {
///     [WINDOW_NAME]()
/// }
/// .windowStyle(.volumetric)
/// .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
/// ```
struct [WINDOW_NAME]: View {

    // MARK: - Properties

    /// RealityKit root entity for 3D content
    @State private var rootEntity = Entity()

    /// Content entity that holds all 3D models
    @State private var contentEntity = Entity()

    /// Animation controller for smooth transitions
    @State private var animationController: AnimationPlaybackController?

    /// Current interaction state
    @State private var interactionState: InteractionState = .idle

    /// Entity selection state
    @State private var selectedEntity: Entity?

    /// Spatial position tracking
    @State private var spatialPosition: SIMD3<Float> = SIMD3(0, 0, 0)

    /// Scale factor for content
    @State private var contentScale: Float = 1.0

    /// Rotation state for content
    @State private var contentRotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)

    /// Environment light settings
    @State private var environmentLighting: EnvironmentLighting = .automatic

    // MARK: - Enums

    /// User interaction states
    enum InteractionState {
        case idle
        case hovering(Entity)
        case selecting(Entity)
        case dragging(Entity, offset: SIMD3<Float>)
    }

    /// Environment lighting options
    enum EnvironmentLighting: CaseIterable {
        case automatic
        case bright
        case dim
        case custom

        var description: String {
            switch self {
            case .automatic: return "Automatic"
            case .bright: return "Bright"
            case .dim: return "Dim"
            case .custom: return "Custom"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize the volumetric window
    init() {
        // Setup will be performed in onAppear
    }

    // MARK: - Body

    var body: some View {
        RealityView { content, attachments in
            // Setup the 3D scene
            await setupRealityScene(content: content)

            // Add any attachments
            if let controlsAttachment = attachments.entity(for: "controls") {
                await addControlsAttachment(controlsAttachment, to: content)
            }

            if let infoAttachment = attachments.entity(for: "info") {
                await addInfoAttachment(infoAttachment, to: content)
            }

        } update: { content, attachments in
            // Update scene based on state changes
            await updateRealityScene(content: content)

        } attachments: {
            // Control panel attachment
            Attachment(id: "controls") {
                controlsPanel
            }

            // Information panel attachment
            Attachment(id: "info") {
                informationPanel
            }
        }
        .gesture(spatialTapGesture)
        .gesture(spatialDragGesture)
        .onAppear {
            setupScene()
        }
        .onDisappear {
            cleanupScene()
        }
        .task {
            await loadContent()
        }
    }

    // MARK: - UI Attachments

    /// Control panel for manipulating 3D content
    @ViewBuilder
    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.title2)
                .fontWeight(.semibold)

            // Scale controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Scale")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("-", action: decreaseScale)
                        .buttonStyle(.borderless)

                    Slider(value: $contentScale, in: 0.1...3.0) { _ in
                        updateContentScale()
                    }

                    Button("+", action: increaseScale)
                        .buttonStyle(.borderless)
                }
            }

            // Rotation controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Rotation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("↶") { rotateContent(axis: .y, angle: -15) }
                        .buttonStyle(.borderless)

                    Button("Reset") { resetContentTransform() }
                        .buttonStyle(.bordered)

                    Button("↷") { rotateContent(axis: .y, angle: 15) }
                        .buttonStyle(.borderless)
                }
            }

            // Lighting controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Lighting")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Lighting", selection: $environmentLighting) {
                    ForEach(EnvironmentLighting.allCases, id: \.self) { option in
                        Text(option.description).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: environmentLighting) { _, newValue in
                    updateEnvironmentLighting(newValue)
                }
            }

            Divider()

            // Action buttons
            VStack(spacing: 8) {
                Button("[PRIMARY_ACTION]") {
                    performPrimaryAction()
                }
                .buttonStyle(.borderedProminent)

                Button("[SECONDARY_ACTION]") {
                    performSecondaryAction()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(width: 300)
    }

    /// Information panel showing current state
    @ViewBuilder
    private var informationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                InfoRow(label: "Scale", value: String(format: "%.2f", contentScale))
                InfoRow(label: "Position", value: formatPosition(spatialPosition))
                InfoRow(label: "Entities", value: "\(contentEntity.children.count)")
                InfoRow(label: "State", value: interactionStateDescription)
            }

            if let selectedEntity = selectedEntity {
                Divider()

                Text("Selected Entity")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Name", value: selectedEntity.name)
                    InfoRow(label: "Components", value: "\(selectedEntity.components.count)")
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(width: 250)
    }

    // MARK: - Supporting Views

    /// Information row component
    struct InfoRow: View {
        let label: String
        let value: String

        var body: some View {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }

    // MARK: - Gesture Handling

    /// Spatial tap gesture for selection
    private var spatialTapGesture: some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { value in
                // TODO: Implement entity selection based on tap location
                handleSpatialTap(at: value.location)
            }
    }

    /// Spatial drag gesture for manipulation
    private var spatialDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }

    // MARK: - RealityKit Scene Setup

    /// Setup the initial RealityKit scene
    @MainActor
    private func setupRealityScene(content: RealityViewContent) async {
        // Add root entity to content
        content.add(rootEntity)

        // Setup content entity as child of root
        contentEntity.name = "ContentEntity"
        rootEntity.addChild(contentEntity)

        // Configure initial lighting
        await setupEnvironmentLighting()

        // Load and setup 3D models
        await load3DModels()
    }

    /// Update the RealityKit scene based on state changes
    @MainActor
    private func updateRealityScene(content: RealityViewContent) async {
        // Update content transform
        updateContentTransform()

        // Update lighting if changed
        updateSceneLighting()

        // Handle interaction state changes
        updateInteractionVisuals()
    }

    /// Setup environment lighting
    private func setupEnvironmentLighting() async {
        // TODO: Configure environment lighting based on settings

        // Example: Add environment lighting
        let lightEntity = Entity()
        lightEntity.components.set(DirectionalLightComponent(
            color: .white,
            intensity: 1000,
            isRealWorldProxy: false
        ))
        lightEntity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [1, 0, 0])
        rootEntity.addChild(lightEntity)
    }

    /// Load and setup 3D models
    private func load3DModels() async {
        do {
            // TODO: Load your 3D models here
            // Example loading a model from RealityKitContent bundle

            // Load main model
            if let mainModel = try await Entity(named: "[MODEL_NAME]", in: realityKitContentBundle) {
                mainModel.name = "MainModel"
                mainModel.position = SIMD3(0, 0, 0)
                contentEntity.addChild(mainModel)

                // Setup interaction components
                setupEntityInteraction(mainModel)
            }

            // Load additional models
            await loadAdditionalModels()

        } catch {
            print("Error loading 3D models: \(error)")
        }
    }

    /// Load additional 3D models
    private func loadAdditionalModels() async {
        // TODO: Load additional models as needed

        // Example: Generate procedural content
        let geometryEntity = createProceduralGeometry()
        geometryEntity.position = SIMD3(0.3, 0, 0)
        contentEntity.addChild(geometryEntity)
    }

    /// Create procedural geometry
    private func createProceduralGeometry() -> Entity {
        let entity = Entity()
        entity.name = "ProceduralGeometry"

        // Create a simple box mesh
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))

        // Setup interaction
        setupEntityInteraction(entity)

        return entity
    }

    /// Setup entity interaction components
    private func setupEntityInteraction(_ entity: Entity) {
        // Enable input target for selection
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))

        // Enable hover effects
        entity.components.set(HoverEffectComponent())

        // Enable collision detection
        let shape = ShapeResource.generateBox(size: entity.visualBounds(relativeTo: nil).extents)
        entity.components.set(CollisionComponent(shapes: [shape]))
    }

    // MARK: - Control Actions

    /// Increase content scale
    private func increaseScale() {
        withAnimation {
            contentScale = min(contentScale + 0.1, 3.0)
            updateContentScale()
        }
    }

    /// Decrease content scale
    private func decreaseScale() {
        withAnimation {
            contentScale = max(contentScale - 0.1, 0.1)
            updateContentScale()
        }
    }

    /// Update content scale
    private func updateContentScale() {
        contentEntity.scale = SIMD3(repeating: contentScale)
    }

    /// Rotate content around specified axis
    private func rotateContent(axis: SIMD3<Float>, angle: Float) {
        let rotation = simd_quatf(angle: angle * .pi / 180, axis: axis)
        contentRotation = simd_mul(contentRotation, rotation)
        updateContentTransform()
    }

    /// Reset content transform to default
    private func resetContentTransform() {
        withAnimation(.easeInOut(duration: 0.5)) {
            contentScale = 1.0
            contentRotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            spatialPosition = SIMD3(0, 0, 0)
            updateContentTransform()
        }
    }

    /// Update content transform based on current state
    private func updateContentTransform() {
        contentEntity.scale = SIMD3(repeating: contentScale)
        contentEntity.orientation = contentRotation
        contentEntity.position = spatialPosition
    }

    /// Update environment lighting
    private func updateEnvironmentLighting(_ lighting: EnvironmentLighting) {
        // TODO: Implement lighting changes based on selection
        switch lighting {
        case .automatic:
            break // Use system automatic lighting
        case .bright:
            break // Increase ambient lighting
        case .dim:
            break // Decrease ambient lighting
        case .custom:
            break // Apply custom lighting setup
        }
    }

    /// Update scene lighting
    private func updateSceneLighting() {
        // TODO: Apply lighting changes to scene
    }

    /// Update interaction visuals
    private func updateInteractionVisuals() {
        // TODO: Update visual feedback based on interaction state
        switch interactionState {
        case .idle:
            // Reset all highlighting
            break
        case .hovering(let entity):
            // Highlight hovered entity
            highlightEntity(entity, intensity: 0.3)
        case .selecting(let entity):
            // Highlight selected entity
            highlightEntity(entity, intensity: 0.6)
        case .dragging(let entity, _):
            // Show dragging visual feedback
            highlightEntity(entity, intensity: 0.9)
        }
    }

    /// Highlight an entity
    private func highlightEntity(_ entity: Entity, intensity: Float) {
        // TODO: Implement entity highlighting
        // Example: Add emission component or change material properties
    }

    // MARK: - Interaction Handlers

    /// Handle spatial tap at location
    private func handleSpatialTap(at location: SIMD3<Double>) {
        // TODO: Implement entity selection based on ray casting
        print("Spatial tap at: \(location)")

        // Example: Simple entity selection
        if let entity = findEntityAtLocation(location) {
            selectedEntity = entity
            interactionState = .selecting(entity)

            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            selectedEntity = nil
            interactionState = .idle
        }
    }

    /// Handle drag gesture changes
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard let selectedEntity = selectedEntity else { return }

        let offset = SIMD3<Float>(
            Float(value.translation.x) * 0.001,
            -Float(value.translation.y) * 0.001,
            0
        )

        interactionState = .dragging(selectedEntity, offset: offset)
        spatialPosition = spatialPosition + offset
        updateContentTransform()
    }

    /// Handle drag gesture end
    private func handleDragEnded(_ value: DragGesture.Value) {
        interactionState = selectedEntity != nil ? .selecting(selectedEntity!) : .idle
    }

    /// Find entity at specified location
    private func findEntityAtLocation(_ location: SIMD3<Double>) -> Entity? {
        // TODO: Implement proper ray casting to find entities
        // This is a simplified example
        if !contentEntity.children.isEmpty {
            return contentEntity.children.first
        }
        return nil
    }

    // MARK: - Primary Actions

    /// Perform primary action
    private func performPrimaryAction() {
        // TODO: Implement your primary action
        print("Primary action performed")

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Example: Animate all entities
            for entity in contentEntity.children {
                // Create a simple animation
                let animation = FromToByAnimation(
                    by: Transform(scale: SIMD3(repeating: 1.1)),
                    duration: 0.3,
                    bindTarget: .transform
                )
                entity.playAnimation(animation.repeat(count: 2))
            }
        }
    }

    /// Perform secondary action
    private func performSecondaryAction() {
        // TODO: Implement your secondary action
        print("Secondary action performed")

        // Example: Add a new procedural entity
        let newEntity = createProceduralGeometry()
        newEntity.position = SIMD3(
            Float.random(in: -0.5...0.5),
            Float.random(in: -0.3...0.3),
            Float.random(in: -0.5...0.5)
        )
        contentEntity.addChild(newEntity)
    }

    // MARK: - Lifecycle Methods

    /// Setup scene when view appears
    private func setupScene() {
        // TODO: Initialize any non-RealityKit resources
        print("[\(String(describing: Self.self))] Scene setup")
    }

    /// Cleanup scene when view disappears
    private func cleanupScene() {
        // TODO: Clean up resources
        animationController?.stop()
        animationController = nil
        selectedEntity = nil
        interactionState = .idle

        print("[\(String(describing: Self.self))] Scene cleanup")
    }

    /// Load content asynchronously
    private func loadContent() async {
        // TODO: Load any additional content that requires async operations
        print("[\(String(describing: Self.self))] Loading content...")

        // Simulate loading time
        try? await Task.sleep(for: .milliseconds(100))

        print("[\(String(describing: Self.self))] Content loaded")
    }

    // MARK: - Utility Methods

    /// Format position for display
    private func formatPosition(_ position: SIMD3<Float>) -> String {
        return String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z)
    }

    /// Get interaction state description
    private var interactionStateDescription: String {
        switch interactionState {
        case .idle:
            return "Idle"
        case .hovering:
            return "Hovering"
        case .selecting:
            return "Selected"
        case .dragging:
            return "Dragging"
        }
    }
}

// MARK: - Attachments Extension

extension [WINDOW_NAME] {
    /// Add controls attachment to the scene
    @MainActor
    private func addControlsAttachment(_ attachment: Entity, to content: RealityViewContent) async {
        // Position the controls attachment
        attachment.position = SIMD3(-0.8, 0.3, 0)
        content.add(attachment)
    }

    /// Add info attachment to the scene
    @MainActor
    private func addInfoAttachment(_ attachment: Entity, to content: RealityViewContent) async {
        // Position the info attachment
        attachment.position = SIMD3(0.6, 0.3, 0)
        content.add(attachment)
    }
}

// MARK: - Preview

#Preview("Volumetric Window") {
    [WINDOW_NAME]()
        .frame(width: 600, height: 600, depth: 600)
}

// MARK: - Template Placeholders
//
// Replace these placeholders when using this template:
//
// [WINDOW_NAME] - Name of your volumetric window struct
// [PROJECT_NAME] - Name of your project
// [AUTHOR] - Author name
// [DATE] - Creation date
// [DESCRIPTION] - Brief description of the window
// [WINDOW_DESCRIPTION] - Detailed description of what the window does
// [FEATURE_1] - First main feature
// [FEATURE_2] - Second main feature
// [FEATURE_3] - Third main feature
// [WINDOW_TITLE] - Title for the window group
// [WINDOW_ID] - Unique identifier for the window
// [MODEL_NAME] - Name of the main 3D model to load
// [PRIMARY_ACTION] - Primary action button text
// [SECONDARY_ACTION] - Secondary action button text
//
// Example replacements:
// [WINDOW_NAME] -> ModelViewerWindow
// [WINDOW_TITLE] -> "3D Model Viewer"
// [WINDOW_ID] -> "model-viewer"
// [MODEL_NAME] -> "Robot"
// [PRIMARY_ACTION] -> "Animate"
// [SECONDARY_ACTION] -> "Add Object"