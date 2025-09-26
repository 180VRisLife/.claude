//
//  [ENTITY_NAME].swift
//  [PROJECT_NAME]
//
//  Created by [AUTHOR] on [DATE].
//
//  [DESCRIPTION]
//

import Foundation
import RealityKit
import RealityKitContent

/// [ENTITY_DESCRIPTION]
///
/// This entity provides:
/// - [FEATURE_1]
/// - [FEATURE_2]
/// - [FEATURE_3]
///
/// Usage:
/// ```swift
/// let entity = [ENTITY_NAME]()
/// await entity.setup()
/// parentEntity.addChild(entity)
/// ```
@MainActor
final class [ENTITY_NAME]: Entity, HasModel, HasCollision, HasInputTarget, HasHoverEffect {

    // MARK: - Properties

    /// Entity configuration
    private let configuration: [ENTITY_NAME]Configuration

    /// Current state of the entity
    private(set) var state: EntityState = .inactive

    /// Animation controllers for managing animations
    private var animationControllers: [String: AnimationPlaybackController] = [:]

    /// Material properties for dynamic visual changes
    private var originalMaterials: [Material] = []

    /// Physics body for collision and interaction
    private var physicsBody: PhysicsBodyComponent?

    /// Custom components for entity-specific behavior
    private var customComponents: [any Component] = []

    /// Interaction delegate for handling user input
    weak var interactionDelegate: [ENTITY_NAME]InteractionDelegate?

    /// Current transform state for animations
    private var baseTransform = Transform.identity

    // MARK: - Configuration

    /// Configuration options for the entity
    struct [ENTITY_NAME]Configuration {
        /// Enable physics simulation
        let enablePhysics: Bool

        /// Enable user interaction
        let enableInteraction: Bool

        /// Enable hover effects
        let enableHoverEffect: Bool

        /// Custom scale factor
        let scaleFactor: Float

        /// Material properties
        let materialProperties: MaterialProperties

        /// Animation settings
        let animationSettings: AnimationSettings

        /// Default configuration
        static let `default` = [ENTITY_NAME]Configuration(
            enablePhysics: false,
            enableInteraction: true,
            enableHoverEffect: true,
            scaleFactor: 1.0,
            materialProperties: .default,
            animationSettings: .default
        )
    }

    /// Material properties configuration
    struct MaterialProperties {
        let baseColor: SimpleMaterial.Color
        let metallic: Float
        let roughness: Float
        let emissiveColor: SimpleMaterial.Color
        let emissiveIntensity: Float

        static let `default` = MaterialProperties(
            baseColor: .white,
            metallic: 0.0,
            roughness: 0.5,
            emissiveColor: .black,
            emissiveIntensity: 0.0
        )
    }

    /// Animation settings
    struct AnimationSettings {
        let defaultDuration: TimeInterval
        let springResponse: Float
        let springDamping: Float
        let enableAutoAnimation: Bool

        static let `default` = AnimationSettings(
            defaultDuration: 1.0,
            springResponse: 0.5,
            springDamping: 0.8,
            enableAutoAnimation: false
        )
    }

    // MARK: - Enums

    /// Entity state
    enum EntityState {
        case inactive
        case initializing
        case active
        case animating
        case interacting
        case destroyed
    }

    /// Animation types
    enum AnimationType: String, CaseIterable {
        case idle = "idle"
        case hover = "hover"
        case selection = "selection"
        case activation = "activation"
        case custom = "custom"
    }

    /// Interaction types
    enum InteractionType {
        case tap
        case longPress
        case drag
        case hover
    }

    // MARK: - Errors

    /// Entity-specific errors
    enum EntityError: LocalizedError {
        case initializationFailed
        case modelLoadingFailed(String)
        case animationNotFound(String)
        case componentMissing(String)

        var errorDescription: String? {
            switch self {
            case .initializationFailed:
                return "Failed to initialize entity"
            case .modelLoadingFailed(let modelName):
                return "Failed to load model: \(modelName)"
            case .animationNotFound(let animationName):
                return "Animation not found: \(animationName)"
            case .componentMissing(let componentName):
                return "Required component missing: \(componentName)"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize the entity with configuration
    /// - Parameter configuration: Entity configuration options
    required init(configuration: [ENTITY_NAME]Configuration = .default) {
        self.configuration = configuration
        super.init()

        self.name = "[ENTITY_NAME]"
    }

    /// Initialize from a model entity
    convenience init(from modelEntity: ModelEntity, configuration: [ENTITY_NAME]Configuration = .default) {
        self.init(configuration: configuration)

        // Copy components from the source entity
        if let modelComponent = modelEntity.model {
            self.components.set(modelComponent)
        }

        if let transformComponent = modelEntity.components[TransformComponent.self] {
            self.components.set(transformComponent)
        }

        // Copy transform
        self.transform = modelEntity.transform
    }

    @available(*, unavailable)
    required init() {
        fatalError("Use init(configuration:) instead")
    }

    deinit {
        cleanup()
    }

    // MARK: - Setup Methods

    /// Setup the entity with all necessary components
    /// - Throws: EntityError if setup fails
    func setup() async throws {
        guard state == .inactive else {
            print("[\(name)] Entity already initialized")
            return
        }

        state = .initializing

        do {
            // Load model and materials
            try await loadModel()

            // Setup components
            try setupComponents()

            // Apply configuration
            applyConfiguration()

            // Setup interactions
            if configuration.enableInteraction {
                setupInteractions()
            }

            // Setup physics
            if configuration.enablePhysics {
                setupPhysics()
            }

            // Setup hover effects
            if configuration.enableHoverEffect {
                setupHoverEffects()
            }

            // Start auto-animations if enabled
            if configuration.animationSettings.enableAutoAnimation {
                try await startAutoAnimation()
            }

            state = .active
            print("[\(name)] Entity setup completed")

        } catch {
            state = .inactive
            throw EntityError.initializationFailed
        }
    }

    /// Load the 3D model for this entity
    private func loadModel() async throws {
        do {
            // TODO: Replace with your actual model loading logic
            let modelEntity = try await Entity(named: "[MODEL_NAME]", in: realityKitContentBundle)

            // Extract model component
            if let modelComponent = modelEntity.components[ModelComponent.self] {
                self.components.set(modelComponent)

                // Store original materials for later restoration
                originalMaterials = modelComponent.materials
            } else {
                // Create a default model if none exists
                createDefaultModel()
            }

        } catch {
            print("[\(name)] Failed to load model: \(error)")
            // Fallback to default geometry
            createDefaultModel()
        }
    }

    /// Create a default model when loading fails
    private func createDefaultModel() {
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = createDefaultMaterial()
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        self.components.set(modelComponent)
        originalMaterials = [material]
    }

    /// Setup all required components
    private func setupComponents() throws {
        // Transform component (usually inherited)
        if !components.has(TransformComponent.self) {
            components.set(TransformComponent(
                scale: SIMD3(repeating: configuration.scaleFactor),
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                translation: SIMD3.zero
            ))
        }

        // Store base transform
        baseTransform = transform

        // Add custom components
        for component in customComponents {
            components.set(component)
        }
    }

    /// Apply configuration settings
    private func applyConfiguration() {
        // Apply scale
        scale = SIMD3(repeating: configuration.scaleFactor)

        // Apply material properties
        updateMaterials()
    }

    /// Setup user interactions
    private func setupInteractions() {
        // Input target for selection
        components.set(InputTargetComponent(allowedInputTypes: .all))

        // Collision for interaction detection
        let bounds = visualBounds(relativeTo: nil)
        let shape = ShapeResource.generateBox(size: bounds.extents)
        components.set(CollisionComponent(shapes: [shape]))
    }

    /// Setup physics simulation
    private func setupPhysics() {
        let bounds = visualBounds(relativeTo: nil)
        let shape = ShapeResource.generateBox(size: bounds.extents)

        // Create physics body
        physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .dynamic
        )

        components.set(physicsBody!)
        components.set(CollisionComponent(shapes: [shape]))
    }

    /// Setup hover effects
    private func setupHoverEffects() {
        components.set(HoverEffectComponent())
    }

    // MARK: - Animation Methods

    /// Start auto-animation loop
    private func startAutoAnimation() async throws {
        // TODO: Implement your auto-animation logic
        let rotationAnimation = createRotationAnimation()
        playAnimation(rotationAnimation, for: .idle)
    }

    /// Create a rotation animation
    private func createRotationAnimation() -> AnimationResource {
        let rotation = FromToByAnimation<Transform>(
            from: Transform(rotation: simd_quatf(angle: 0, axis: [0, 1, 0])),
            to: Transform(rotation: simd_quatf(angle: 2 * .pi, axis: [0, 1, 0])),
            duration: configuration.animationSettings.defaultDuration
        )
        return try! AnimationResource.generate(with: rotation)
    }

    /// Play animation for specific type
    /// - Parameters:
    ///   - animation: Animation resource to play
    ///   - type: Type of animation
    ///   - completion: Completion handler
    func playAnimation(
        _ animation: AnimationResource,
        for type: AnimationType,
        completion: (() -> Void)? = nil
    ) {
        state = .animating

        let controller = playAnimation(animation.repeat(count: type == .idle ? .max : 1))
        animationControllers[type.rawValue] = controller

        // Handle completion
        if let completion = completion {
            Task {
                await controller.completion
                await MainActor.run {
                    completion()
                    self.state = .active
                }
            }
        }
    }

    /// Stop animation for specific type
    /// - Parameter type: Type of animation to stop
    func stopAnimation(for type: AnimationType) {
        if let controller = animationControllers[type.rawValue] {
            controller.stop()
            animationControllers.removeValue(forKey: type.rawValue)
        }
    }

    /// Stop all animations
    func stopAllAnimations() {
        for controller in animationControllers.values {
            controller.stop()
        }
        animationControllers.removeAll()
        state = .active
    }

    // MARK: - Material Methods

    /// Create default material based on configuration
    private func createDefaultMaterial() -> SimpleMaterial {
        let props = configuration.materialProperties

        var material = SimpleMaterial(
            color: props.baseColor,
            isMetallic: props.metallic > 0.5
        )

        material.roughness = MaterialScalarParameter(floatLiteral: props.roughness)
        material.metallic = MaterialScalarParameter(floatLiteral: props.metallic)

        if props.emissiveIntensity > 0 {
            material.emissiveColor = MaterialColorParameter(color: props.emissiveColor)
        }

        return material
    }

    /// Update materials based on current configuration
    private func updateMaterials() {
        guard var modelComponent = components[ModelComponent.self] else { return }

        var updatedMaterials: [Material] = []

        for material in modelComponent.materials {
            if var simpleMaterial = material as? SimpleMaterial {
                // Update properties
                let props = configuration.materialProperties
                simpleMaterial.baseColor = MaterialColorParameter(color: props.baseColor)
                simpleMaterial.metallic = MaterialScalarParameter(floatLiteral: props.metallic)
                simpleMaterial.roughness = MaterialScalarParameter(floatLiteral: props.roughness)

                if props.emissiveIntensity > 0 {
                    simpleMaterial.emissiveColor = MaterialColorParameter(color: props.emissiveColor)
                }

                updatedMaterials.append(simpleMaterial)
            } else {
                updatedMaterials.append(material)
            }
        }

        modelComponent.materials = updatedMaterials
        components.set(modelComponent)
    }

    /// Highlight the entity with emission
    /// - Parameter intensity: Emission intensity (0.0 to 1.0)
    func highlight(intensity: Float = 0.5) {
        guard var modelComponent = components[ModelComponent.self] else { return }

        var highlightedMaterials: [Material] = []

        for material in modelComponent.materials {
            if var simpleMaterial = material as? SimpleMaterial {
                simpleMaterial.emissiveColor = MaterialColorParameter(color: .white)
                // Note: EmissiveIntensity is not directly available in SimpleMaterial
                // You may need to use UnlitMaterial or PhysicallyBasedMaterial for more control
                highlightedMaterials.append(simpleMaterial)
            } else {
                highlightedMaterials.append(material)
            }
        }

        modelComponent.materials = highlightedMaterials
        components.set(modelComponent)
    }

    /// Remove highlight effect
    func removeHighlight() {
        guard var modelComponent = components[ModelComponent.self] else { return }
        modelComponent.materials = originalMaterials
        components.set(modelComponent)
    }

    // MARK: - Interaction Handling

    /// Handle user interaction
    /// - Parameter type: Type of interaction
    func handleInteraction(type: InteractionType) {
        state = .interacting

        switch type {
        case .tap:
            handleTap()
        case .longPress:
            handleLongPress()
        case .drag:
            handleDrag()
        case .hover:
            handleHover()
        }

        // Notify delegate
        interactionDelegate?.entity(self, didReceiveInteraction: type)

        state = .active
    }

    /// Handle tap interaction
    private func handleTap() {
        // Create tap animation
        let scaleAnimation = createScaleAnimation(from: 1.0, to: 1.2, duration: 0.2)
        playAnimation(scaleAnimation, for: .selection)

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    /// Handle long press interaction
    private func handleLongPress() {
        highlight(intensity: 0.8)

        // Long press haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Remove highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.removeHighlight()
        }
    }

    /// Handle drag interaction
    private func handleDrag() {
        // TODO: Implement drag-specific behavior
        print("[\(name)] Drag interaction")
    }

    /// Handle hover interaction
    private func handleHover() {
        highlight(intensity: 0.3)

        // Create gentle hover animation
        let hoverAnimation = createScaleAnimation(from: 1.0, to: 1.05, duration: 0.3)
        playAnimation(hoverAnimation, for: .hover)
    }

    /// Create scale animation
    private func createScaleAnimation(from: Float, to: Float, duration: TimeInterval) -> AnimationResource {
        let scaleAnimation = FromToByAnimation<Transform>(
            from: Transform(scale: SIMD3(repeating: from)),
            to: Transform(scale: SIMD3(repeating: to)),
            duration: duration
        )
        return try! AnimationResource.generate(with: scaleAnimation)
    }

    // MARK: - Physics Methods

    /// Apply impulse to the entity
    /// - Parameter impulse: Force vector to apply
    func applyImpulse(_ impulse: SIMD3<Float>) {
        guard configuration.enablePhysics,
              var physicsBody = components[PhysicsBodyComponent.self] else {
            return
        }

        // Note: Direct impulse application would require a physics world context
        // This is a simplified example
        physicsBody.mode = .dynamic
        components.set(physicsBody)

        // You would typically apply the impulse through the physics world
        print("[\(name)] Applied impulse: \(impulse)")
    }

    /// Enable/disable physics simulation
    /// - Parameter enabled: Whether physics should be enabled
    func setPhysicsEnabled(_ enabled: Bool) {
        if enabled && !components.has(PhysicsBodyComponent.self) {
            setupPhysics()
        } else if !enabled && components.has(PhysicsBodyComponent.self) {
            components.remove(PhysicsBodyComponent.self)
        }
    }

    // MARK: - Utility Methods

    /// Reset entity to its original state
    func reset() {
        stopAllAnimations()
        removeHighlight()
        transform = baseTransform
        state = .active
    }

    /// Cleanup entity resources
    private func cleanup() {
        stopAllAnimations()
        customComponents.removeAll()
        originalMaterials.removeAll()
        interactionDelegate = nil
    }

    /// Get current bounds of the entity
    var currentBounds: BoundingBox {
        return visualBounds(relativeTo: nil)
    }

    /// Check if entity is currently animating
    var isAnimating: Bool {
        return state == .animating && !animationControllers.isEmpty
    }
}

// MARK: - Component Extensions

extension [ENTITY_NAME] {
    /// Add a custom component to the entity
    /// - Parameter component: Component to add
    func addCustomComponent<T: Component>(_ component: T) {
        components.set(component)
        customComponents.append(component)
    }

    /// Remove a custom component from the entity
    /// - Parameter componentType: Type of component to remove
    func removeCustomComponent<T: Component>(_ componentType: T.Type) {
        components.remove(componentType)
        customComponents.removeAll { type(of: $0) == componentType }
    }

    /// Check if entity has a specific component
    /// - Parameter componentType: Type of component to check
    /// - Returns: True if component exists
    func hasComponent<T: Component>(_ componentType: T.Type) -> Bool {
        return components.has(componentType)
    }
}

// MARK: - Interaction Delegate

/// Delegate protocol for handling entity interactions
protocol [ENTITY_NAME]InteractionDelegate: AnyObject {
    /// Called when entity receives user interaction
    /// - Parameters:
    ///   - entity: The entity that received interaction
    ///   - type: Type of interaction received
    func entity(_ entity: [ENTITY_NAME], didReceiveInteraction type: [ENTITY_NAME].InteractionType)
}

// MARK: - Factory Methods

extension [ENTITY_NAME] {
    /// Create a basic entity with default configuration
    /// - Returns: Configured entity ready for use
    static func createBasic() -> [ENTITY_NAME] {
        return [ENTITY_NAME](configuration: .default)
    }

    /// Create an interactive entity
    /// - Returns: Configured entity with interaction enabled
    static func createInteractive() -> [ENTITY_NAME] {
        let config = [ENTITY_NAME]Configuration(
            enablePhysics: false,
            enableInteraction: true,
            enableHoverEffect: true,
            scaleFactor: 1.0,
            materialProperties: .default,
            animationSettings: .default
        )
        return [ENTITY_NAME](configuration: config)
    }

    /// Create a physics-enabled entity
    /// - Returns: Configured entity with physics simulation
    static func createWithPhysics() -> [ENTITY_NAME] {
        let config = [ENTITY_NAME]Configuration(
            enablePhysics: true,
            enableInteraction: true,
            enableHoverEffect: false,
            scaleFactor: 1.0,
            materialProperties: .default,
            animationSettings: .default
        )
        return [ENTITY_NAME](configuration: config)
    }
}

// MARK: - Template Placeholders
//
// Replace these placeholders when using this template:
//
// [ENTITY_NAME] - Name of your entity class
// [PROJECT_NAME] - Name of your project
// [AUTHOR] - Author name
// [DATE] - Creation date
// [DESCRIPTION] - Brief description of the entity
// [ENTITY_DESCRIPTION] - Detailed description of what the entity does
// [FEATURE_1] - First main feature
// [FEATURE_2] - Second main feature
// [FEATURE_3] - Third main feature
// [MODEL_NAME] - Name of the 3D model file to load
//
// Example replacements:
// [ENTITY_NAME] -> InteractiveRobot
// [MODEL_NAME] -> "robot_model"
// [FEATURE_1] -> Interactive gesture recognition
// [FEATURE_2] -> Physics-based movement
// [FEATURE_3] -> Customizable materials and animations