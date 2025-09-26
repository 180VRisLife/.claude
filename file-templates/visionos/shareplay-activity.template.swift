//
//  [ACTIVITY_NAME].swift
//  [PROJECT_NAME]
//
//  Created by [AUTHOR] on [DATE].
//
//  [DESCRIPTION]
//

import Foundation
import GroupActivities
import Combine
import os.log

/// [ACTIVITY_DESCRIPTION]
///
/// This SharePlay activity provides:
/// - [FEATURE_1]
/// - [FEATURE_2]
/// - [FEATURE_3]
///
/// Usage:
/// ```swift
/// let activity = [ACTIVITY_NAME](metadata: activityMetadata)
/// let manager = [ACTIVITY_NAME]Manager()
/// await manager.startActivity(activity)
/// ```
struct [ACTIVITY_NAME]: GroupActivity {

    // MARK: - Properties

    /// Metadata for the GroupActivity
    var metadata: GroupActivityMetadata

    /// Activity configuration
    let configuration: ActivityConfiguration

    // MARK: - Configuration

    /// Configuration options for the SharePlay activity
    struct ActivityConfiguration: Codable {
        /// Maximum number of participants allowed
        let maxParticipants: Int

        /// Enable spatial audio
        let enableSpatialAudio: Bool

        /// Enable screen recording during activity
        let enableScreenRecording: Bool

        /// Custom session settings
        let sessionSettings: SessionSettings

        /// Default configuration
        static let `default` = ActivityConfiguration(
            maxParticipants: 32,
            enableSpatialAudio: true,
            enableScreenRecording: false,
            sessionSettings: .default
        )
    }

    /// Session-specific settings
    struct SessionSettings: Codable {
        /// Synchronization mode for shared state
        let syncMode: SyncMode

        /// Data sharing permissions
        let dataSharing: DataSharingMode

        /// Network quality requirements
        let networkQuality: NetworkQuality

        /// Default settings
        static let `default` = SessionSettings(
            syncMode: .realtime,
            dataSharing: .required,
            networkQuality: .high
        )

        enum SyncMode: String, Codable, CaseIterable {
            case realtime = "realtime"
            case buffered = "buffered"
            case eventual = "eventual"
        }

        enum DataSharingMode: String, Codable, CaseIterable {
            case required = "required"
            case optional = "optional"
            case disabled = "disabled"
        }

        enum NetworkQuality: String, Codable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
        }
    }

    // MARK: - Initialization

    /// Initialize the SharePlay activity
    /// - Parameters:
    ///   - metadata: GroupActivity metadata
    ///   - configuration: Activity configuration
    init(metadata: GroupActivityMetadata, configuration: ActivityConfiguration = .default) {
        self.metadata = metadata
        self.configuration = configuration
    }

    /// Convenience initializer with common settings
    /// - Parameters:
    ///   - title: Activity title
    ///   - subtitle: Activity subtitle
    ///   - imageURL: URL for activity thumbnail
    ///   - configuration: Activity configuration
    init(
        title: String,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        configuration: ActivityConfiguration = .default
    ) {
        var metadata = GroupActivityMetadata()
        metadata.title = title
        metadata.subtitle = subtitle
        metadata.previewImage = imageURL
        metadata.type = .generic

        self.init(metadata: metadata, configuration: configuration)
    }
}

// MARK: - Activity Manager

/// Manager class for handling SharePlay activity lifecycle and coordination
@MainActor
@Observable
final class [ACTIVITY_NAME]Manager: ObservableObject {

    // MARK: - Properties

    /// Current GroupSession if activity is active
    private(set) var groupSession: GroupSession<[ACTIVITY_NAME]>?

    /// Messenger for real-time communication
    private(set) var messenger: GroupSessionMessenger?

    /// Current activity state
    private(set) var state: ActivityState = .inactive

    /// List of current participants
    private(set) var participants: [Participant] = []

    /// Shared state coordinator
    private var coordinator: GroupStateCoordinator?

    /// Subscription management
    private var subscriptions = Set<AnyCancellable>()

    /// Logger for debugging
    private let logger = Logger(subsystem: "[BUNDLE_ID]", category: "[ACTIVITY_NAME]Manager")

    /// Activity configuration
    private var activityConfiguration: [ACTIVITY_NAME].ActivityConfiguration = .default

    /// Delegate for handling activity events
    weak var delegate: [ACTIVITY_NAME]ManagerDelegate?

    // MARK: - Enums

    /// Activity lifecycle states
    enum ActivityState {
        case inactive
        case preparing
        case active
        case waiting
        case ended
        case error(Error)
    }

    /// Participant information
    struct Participant: Identifiable, Hashable {
        let id: UUID
        let name: String
        let isLocalParticipant: Bool
        let joinedAt: Date

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Participant, rhs: Participant) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Errors

    /// Activity-specific errors
    enum ActivityError: LocalizedError {
        case activityNotSupported
        case sessionCreationFailed
        case messengerSetupFailed
        case participantLimitExceeded
        case networkConnectionFailed
        case authorizationDenied

        var errorDescription: String? {
            switch self {
            case .activityNotSupported:
                return "SharePlay activity is not supported on this device"
            case .sessionCreationFailed:
                return "Failed to create group session"
            case .messengerSetupFailed:
                return "Failed to setup group messenger"
            case .participantLimitExceeded:
                return "Maximum number of participants exceeded"
            case .networkConnectionFailed:
                return "Network connection failed"
            case .authorizationDenied:
                return "SharePlay authorization was denied"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize the activity manager
    init() {
        setupGroupActivityObserver()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods

    /// Start a new SharePlay activity
    /// - Parameter activity: The activity to start
    /// - Throws: ActivityError if the activity cannot be started
    func startActivity(_ activity: [ACTIVITY_NAME]) async throws {
        guard state != .active else {
            logger.warning("Activity is already active")
            return
        }

        logger.info("Starting SharePlay activity: \(activity.metadata.title)")
        state = .preparing
        activityConfiguration = activity.configuration

        do {
            // Check if GroupActivities are supported
            guard await isGroupActivitySupported() else {
                throw ActivityError.activityNotSupported
            }

            // Activate the activity
            switch await activity.prepareForActivation() {
            case .activationPreferred:
                try await activity.activate()
                logger.info("Activity activated successfully")

            case .activationDisabled:
                state = .inactive
                logger.warning("Activity activation was disabled")

            case .cancelled:
                state = .inactive
                logger.info("Activity activation was cancelled")

            @unknown default:
                state = .inactive
                logger.error("Unknown activation result")
            }

        } catch {
            state = .error(error)
            logger.error("Failed to start activity: \(error.localizedDescription)")
            throw error
        }
    }

    /// End the current SharePlay activity
    func endActivity() async {
        guard let session = groupSession else {
            logger.warning("No active session to end")
            return
        }

        logger.info("Ending SharePlay activity")

        // Leave the session
        session.leave()

        // Cleanup
        await cleanup()

        state = .ended
        delegate?.activityDidEnd()
    }

    /// Send a message to all participants
    /// - Parameter message: Message to send
    /// - Throws: Error if message sending fails
    func sendMessage<T: Codable>(_ message: T) async throws {
        guard let messenger = messenger else {
            throw ActivityError.messengerSetupFailed
        }

        do {
            try await messenger.send(message)
            logger.debug("Message sent successfully")
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
            throw error
        }
    }

    /// Send a message to specific participants
    /// - Parameters:
    ///   - message: Message to send
    ///   - participants: Target participants
    /// - Throws: Error if message sending fails
    func sendMessage<T: Codable>(_ message: T, to participants: [Participant]) async throws {
        guard let messenger = messenger else {
            throw ActivityError.messengerSetupFailed
        }

        // Convert participants to GroupSession participants
        // Note: This is a simplified example - you'd need to map properly
        let targets = participants.compactMap { participant in
            groupSession?.activeParticipants.first { $0.id == participant.id }
        }

        do {
            try await messenger.send(message, to: .only(targets))
            logger.debug("Message sent to \(targets.count) participants")
        } catch {
            logger.error("Failed to send targeted message: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Methods

    /// Check if GroupActivities are supported
    private func isGroupActivitySupported() async -> Bool {
        // Check system support and user permissions
        return true // Simplified - implement actual checks
    }

    /// Setup group activity session observer
    private func setupGroupActivityObserver() {
        Task {
            for await session in [ACTIVITY_NAME].sessions() {
                await configureGroupSession(session)
            }
        }
    }

    /// Configure the group session
    private func configureGroupSession(_ session: GroupSession<[ACTIVITY_NAME]>) async {
        groupSession = session
        state = .active

        logger.info("Group session configured with \(session.activeParticipants.count) participants")

        // Setup participants
        await updateParticipants(session.activeParticipants)

        // Setup messenger
        messenger = GroupSessionMessenger(session: session)

        // Setup coordinator for shared state
        coordinator = GroupStateCoordinator(session: session)

        // Setup session observations
        setupSessionObservers(session)

        // Join the session
        session.join()

        // Notify delegate
        delegate?.activityDidStart(with: participants)
    }

    /// Setup session observers
    private func setupSessionObservers(_ session: GroupSession<[ACTIVITY_NAME]>) {
        // Observe participant changes
        session.$activeParticipants
            .sink { [weak self] participants in
                Task { @MainActor in
                    await self?.updateParticipants(participants)
                }
            }
            .store(in: &subscriptions)

        // Observe session state
        session.$state
            .sink { [weak self] sessionState in
                Task { @MainActor in
                    await self?.handleSessionStateChange(sessionState)
                }
            }
            .store(in: &subscriptions)

        // Setup message handling
        setupMessageHandling()
    }

    /// Update participants list
    private func updateParticipants(_ sessionParticipants: Set<GroupSessionParticipant>) async {
        let newParticipants = sessionParticipants.map { participant in
            Participant(
                id: participant.id,
                name: "Participant", // You'd get actual name from participant info
                isLocalParticipant: participant == groupSession?.localParticipant,
                joinedAt: Date()
            )
        }

        participants = Array(newParticipants)

        // Check participant limits
        if participants.count > activityConfiguration.maxParticipants {
            logger.warning("Participant count (\(participants.count)) exceeds maximum (\(activityConfiguration.maxParticipants))")
        }

        delegate?.participantsDidChange(participants)
    }

    /// Handle session state changes
    private func handleSessionStateChange(_ sessionState: GroupSession<[ACTIVITY_NAME]>.State) async {
        switch sessionState {
        case .waiting:
            state = .waiting
            logger.info("Session is waiting for participants")

        case .joined:
            state = .active
            logger.info("Successfully joined session")

        case .invalidated(let reason):
            state = .ended
            logger.info("Session invalidated: \(String(describing: reason))")
            await cleanup()

        @unknown default:
            logger.warning("Unknown session state: \(sessionState)")
        }
    }

    /// Setup message handling
    private func setupMessageHandling() {
        guard let messenger = messenger else { return }

        // Handle custom messages
        Task {
            for await (message, context) in messenger.messages(of: [MESSAGE_TYPE].self) {
                await handleReceivedMessage(message, from: context.source)
            }
        }

        // Add more message type handlers as needed
    }

    /// Handle received messages
    private func handleReceivedMessage<T>(_ message: T, from participant: GroupSessionParticipant) async {
        logger.debug("Received message from participant: \(participant.id)")

        // TODO: Implement message handling based on your app's needs
        delegate?.didReceiveMessage(message, from: findParticipant(by: participant.id))
    }

    /// Find participant by ID
    private func findParticipant(by id: UUID) -> Participant? {
        return participants.first { $0.id == id }
    }

    /// Cleanup resources
    private func cleanup() async {
        subscriptions.removeAll()
        coordinator = nil
        messenger = nil

        if let session = groupSession {
            session.leave()
        }

        groupSession = nil
        participants.removeAll()
        state = .inactive

        logger.info("Activity cleanup completed")
    }
}

// MARK: - Group State Coordinator

/// Coordinates shared state across participants
@MainActor
final class GroupStateCoordinator {

    // MARK: - Properties

    /// The group session
    private let session: GroupSession<[ACTIVITY_NAME]>

    /// Shared state store
    private var sharedState: [String: Any] = [:]

    /// State change observers
    private var stateObservers: [UUID: (String, Any) -> Void] = [:]

    /// Logger
    private let logger = Logger(subsystem: "[BUNDLE_ID]", category: "GroupStateCoordinator")

    // MARK: - Initialization

    init(session: GroupSession<[ACTIVITY_NAME]>) {
        self.session = session
    }

    // MARK: - Public Methods

    /// Update shared state
    /// - Parameters:
    ///   - key: State key
    ///   - value: State value
    func updateState<T: Codable>(key: String, value: T) async {
        sharedState[key] = value

        // Broadcast state change to all participants
        // TODO: Implement state synchronization mechanism

        // Notify local observers
        notifyObservers(key: key, value: value)
    }

    /// Get shared state value
    /// - Parameter key: State key
    /// - Returns: State value if exists
    func getState<T>(key: String, as type: T.Type) -> T? {
        return sharedState[key] as? T
    }

    /// Observe state changes
    /// - Parameters:
    ///   - key: State key to observe
    ///   - observer: Observer closure
    /// - Returns: Observer ID for removal
    func observeState<T>(key: String, observer: @escaping (T) -> Void) -> UUID {
        let id = UUID()
        stateObservers[id] = { observedKey, value in
            if observedKey == key, let typedValue = value as? T {
                observer(typedValue)
            }
        }
        return id
    }

    /// Remove state observer
    /// - Parameter observerID: Observer ID to remove
    func removeObserver(_ observerID: UUID) {
        stateObservers.removeValue(forKey: observerID)
    }

    // MARK: - Private Methods

    /// Notify observers of state changes
    private func notifyObservers(key: String, value: Any) {
        for observer in stateObservers.values {
            observer(key, value)
        }
    }
}

// MARK: - Delegate Protocol

/// Delegate protocol for activity manager events
@MainActor
protocol [ACTIVITY_NAME]ManagerDelegate: AnyObject {
    /// Called when activity starts
    /// - Parameter participants: Initial participants
    func activityDidStart(with participants: [[ACTIVITY_NAME]Manager.Participant])

    /// Called when activity ends
    func activityDidEnd()

    /// Called when participants change
    /// - Parameter participants: Updated participant list
    func participantsDidChange(_ participants: [[ACTIVITY_NAME]Manager.Participant])

    /// Called when a message is received
    /// - Parameters:
    ///   - message: Received message
    ///   - participant: Sender participant
    func didReceiveMessage<T>(_ message: T, from participant: [ACTIVITY_NAME]Manager.Participant?)

    /// Called when an error occurs
    /// - Parameter error: The error that occurred
    func activityDidEncounterError(_ error: Error)
}

// MARK: - Message Types

/// Example message types for SharePlay communication
enum [MESSAGE_TYPE]: Codable {
    case userAction(ActionMessage)
    case stateSync(StateSyncMessage)
    case chatMessage(ChatMessage)
    case customEvent(CustomEventMessage)

    struct ActionMessage: Codable {
        let action: String
        let parameters: [String: String]
        let timestamp: Date
    }

    struct StateSyncMessage: Codable {
        let stateKey: String
        let stateValue: Data // Encoded value
        let version: Int
    }

    struct ChatMessage: Codable {
        let text: String
        let senderID: UUID
        let timestamp: Date
    }

    struct CustomEventMessage: Codable {
        let eventType: String
        let eventData: [String: Any]

        // Custom coding for Any values
        enum CodingKeys: CodingKey {
            case eventType
            case eventData
        }

        init(eventType: String, eventData: [String: Any]) {
            self.eventType = eventType
            self.eventData = eventData
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            eventType = try container.decode(String.self, forKey: .eventType)
            // Simplified - you'd need proper Any decoding
            eventData = [:]
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(eventType, forKey: .eventType)
            // Simplified - you'd need proper Any encoding
        }
    }
}

// MARK: - Extensions

extension [ACTIVITY_NAME]Manager {
    /// Check if currently in an active SharePlay session
    var isInActiveSession: Bool {
        return groupSession != nil && state == .active
    }

    /// Get current participant count
    var participantCount: Int {
        return participants.count
    }

    /// Get local participant
    var localParticipant: Participant? {
        return participants.first { $0.isLocalParticipant }
    }
}

// MARK: - Preview Support

#if DEBUG
extension [ACTIVITY_NAME] {
    /// Create a sample activity for previews
    static func sample() -> [ACTIVITY_NAME] {
        return [ACTIVITY_NAME](
            title: "[SAMPLE_TITLE]",
            subtitle: "[SAMPLE_SUBTITLE]"
        )
    }
}

extension [ACTIVITY_NAME]Manager {
    /// Create a mock manager for previews
    static func mock() -> [ACTIVITY_NAME]Manager {
        let manager = [ACTIVITY_NAME]Manager()
        manager.state = .active
        manager.participants = [
            Participant(id: UUID(), name: "Local User", isLocalParticipant: true, joinedAt: Date()),
            Participant(id: UUID(), name: "Remote User 1", isLocalParticipant: false, joinedAt: Date()),
            Participant(id: UUID(), name: "Remote User 2", isLocalParticipant: false, joinedAt: Date())
        ]
        return manager
    }
}
#endif

// MARK: - Template Placeholders
//
// Replace these placeholders when using this template:
//
// [ACTIVITY_NAME] - Name of your SharePlay activity
// [PROJECT_NAME] - Name of your project
// [AUTHOR] - Author name
// [DATE] - Creation date
// [DESCRIPTION] - Brief description of the activity
// [ACTIVITY_DESCRIPTION] - Detailed description of what the activity does
// [FEATURE_1] - First main feature
// [FEATURE_2] - Second main feature
// [FEATURE_3] - Third main feature
// [BUNDLE_ID] - Your app's bundle identifier
// [MESSAGE_TYPE] - Name of your message types enum
// [SAMPLE_TITLE] - Sample title for preview
// [SAMPLE_SUBTITLE] - Sample subtitle for preview
//
// Example replacements:
// [ACTIVITY_NAME] -> WatchTogetherActivity
// [MESSAGE_TYPE] -> WatchTogetherMessage
// [SAMPLE_TITLE] -> "Watch Together"
// [SAMPLE_SUBTITLE] -> "Synchronized movie viewing"