import Foundation
import os.log
#if canImport(RealityKit)
import RealityKit
#endif

protocol AnalyticsService {
    func track(event: String, properties: [String: Any]?)
    func setUserProperty(key: String, value: Any)
    func identify(userId: String)
    func startSession()
    func endSession()
    func flush()
}

final class AmplitudeAnalytics: AnalyticsService {
    static let shared = AmplitudeAnalytics()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Analytics")
    private let apiKey: String
    private let baseURL = URL(string: "https://api2.amplitude.com/2/httpapi")!

    private var userId: String?
    private var sessionId: String?
    private var userProperties: [String: Any] = [:]
    private var eventQueue: [AmplitudeEvent] = []
    private let queueLock = NSLock()
    private var flushTimer: Timer?

    private init(apiKey: String = "") {
        self.apiKey = apiKey
        setupFlushTimer()
        setupVisionOSEvents()
    }

    // MARK: - Public API

    func configure(apiKey: String) {
        guard !apiKey.isEmpty else {
            logger.error("Amplitude API key is required")
            return
        }
    }

    func track(event: String, properties: [String: Any]? = nil) {
        guard !apiKey.isEmpty else {
            logger.warning("Amplitude not configured, skipping event: \(event)")
            return
        }

        var eventProperties = properties ?? [:]
        eventProperties["platform"] = "visionOS"
        eventProperties["timestamp"] = Date().timeIntervalSince1970

        let amplitudeEvent = AmplitudeEvent(
            eventType: event,
            userId: userId,
            sessionId: sessionId ?? generateSessionId(),
            eventProperties: eventProperties,
            userProperties: userProperties
        )

        queueLock.withLock {
            eventQueue.append(amplitudeEvent)
        }

        logger.debug("Tracked event: \(event)")

        if eventQueue.count >= 30 {
            flush()
        }
    }

    func setUserProperty(key: String, value: Any) {
        userProperties[key] = value
        logger.debug("Set user property: \(key)")
    }

    func identify(userId: String) {
        self.userId = userId
        track(event: "$identify", properties: ["user_id": userId])
    }

    func startSession() {
        sessionId = generateSessionId()
        track(event: "session_start")
    }

    func endSession() {
        track(event: "session_end")
        flush()
        sessionId = nil
    }

    func flush() {
        guard !apiKey.isEmpty else { return }

        let eventsToSend: [AmplitudeEvent]
        queueLock.withLock {
            eventsToSend = eventQueue
            eventQueue.removeAll()
        }

        guard !eventsToSend.isEmpty else { return }

        Task {
            await sendEvents(eventsToSend)
        }
    }

    // MARK: - VisionOS Specific Events

    private func setupVisionOSEvents() {
        #if os(visionOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.track(event: "app_background", properties: ["platform_event": true])
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.track(event: "app_foreground", properties: ["platform_event": true])
        }
        #endif
    }

    func trackVisionEvent(_ event: VisionEvent) {
        let properties: [String: Any] = [
            "vision_event": true,
            "event_category": event.category,
            "spatial_context": event.spatialContext as Any,
            "interaction_type": event.interactionType
        ]
        track(event: event.name, properties: properties)
    }

    // MARK: - Private Methods

    private func setupFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    private func generateSessionId() -> String {
        return UUID().uuidString + "_" + String(Int(Date().timeIntervalSince1970))
    }

    private func sendEvents(_ events: [AmplitudeEvent]) async {
        let payload = AmplitudePayload(
            apiKey: apiKey,
            events: events
        )

        do {
            let data = try JSONEncoder().encode(payload)
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                logger.debug("Successfully sent \(events.count) events to Amplitude")
            } else {
                logger.error("Failed to send events to Amplitude")
            }
        } catch {
            logger.error("Error sending events to Amplitude: \(error)")

            // Re-queue events on failure
            queueLock.withLock {
                eventQueue.insert(contentsOf: events, at: 0)
            }
        }
    }
}

// MARK: - Data Models

struct AmplitudeEvent: Codable {
    let eventType: String
    let userId: String?
    let sessionId: String?
    let time: TimeInterval
    let eventProperties: [String: Any]?
    let userProperties: [String: Any]?

    init(eventType: String, userId: String?, sessionId: String?, eventProperties: [String: Any]?, userProperties: [String: Any]?) {
        self.eventType = eventType
        self.userId = userId
        self.sessionId = sessionId
        self.time = Date().timeIntervalSince1970
        self.eventProperties = eventProperties
        self.userProperties = userProperties
    }

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case userId = "user_id"
        case sessionId = "session_id"
        case time
        case eventProperties = "event_properties"
        case userProperties = "user_properties"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encode(time, forKey: .time)

        if let eventProperties = eventProperties {
            try container.encode(AnyCodable(eventProperties), forKey: .eventProperties)
        }

        if let userProperties = userProperties {
            try container.encode(AnyCodable(userProperties), forKey: .userProperties)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventType = try container.decode(String.self, forKey: .eventType)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        time = try container.decode(TimeInterval.self, forKey: .time)

        let eventPropsContainer = try? container.decode(AnyCodable.self, forKey: .eventProperties)
        eventProperties = eventPropsContainer?.value as? [String: Any]

        let userPropsContainer = try? container.decode(AnyCodable.self, forKey: .userProperties)
        userProperties = userPropsContainer?.value as? [String: Any]
    }
}

struct AmplitudePayload: Codable {
    let apiKey: String
    let events: [AmplitudeEvent]

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case events
    }
}

struct VisionEvent {
    let name: String
    let category: String
    let spatialContext: [String: Any]?
    let interactionType: String

    static func immersiveSpaceEntered(spaceId: String) -> VisionEvent {
        VisionEvent(
            name: "immersive_space_entered",
            category: "spatial",
            spatialContext: ["space_id": spaceId],
            interactionType: "navigation"
        )
    }

    static func entityInteraction(entityId: String, type: String) -> VisionEvent {
        VisionEvent(
            name: "entity_interaction",
            category: "interaction",
            spatialContext: ["entity_id": entityId],
            interactionType: type
        )
    }

    static func handGestureDetected(gesture: String) -> VisionEvent {
        VisionEvent(
            name: "hand_gesture_detected",
            category: "input",
            spatialContext: ["gesture": gesture],
            interactionType: "hand_tracking"
        )
    }
}

// MARK: - Helper Types

private struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            try container.encode(String(describing: value))
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
}