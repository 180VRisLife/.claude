//
//  [SERVICE_NAME].swift
//  [PROJECT_NAME]
//
//  Created by [AUTHOR] on [DATE].
//
//  [DESCRIPTION]
//

import Foundation
import Observation
import os.log

/// [SERVICE_DESCRIPTION]
///
/// This service provides:
/// - [CAPABILITY_1]
/// - [CAPABILITY_2]
/// - [CAPABILITY_3]
///
/// Usage:
/// ```swift
/// let service = [SERVICE_NAME]()
/// await service.start()
///
/// // Perform operations
/// try await service.[OPERATION_NAME]()
/// ```
@MainActor
@Observable
final class [SERVICE_NAME]: Sendable {

    // MARK: - Properties

    /// Current state of the service
    enum State {
        case idle
        case starting
        case running
        case stopping
        case error(Error)
    }

    /// Current service state
    private(set) var state: State = .idle

    /// Service configuration
    private let configuration: [SERVICE_NAME]Configuration

    /// Internal logger for debugging and monitoring
    private let logger = Logger(subsystem: "[BUNDLE_ID]", category: "[SERVICE_NAME]")

    /// Background task for continuous operations
    private var backgroundTask: Task<Void, Never>?

    /// Cancellation token for stopping operations
    private var isCancelled = false

    // MARK: - Configuration

    /// Configuration options for the service
    struct [SERVICE_NAME]Configuration: Sendable {
        /// Enable debug logging
        let enableDebugLogging: Bool

        /// Maximum retry attempts for failed operations
        let maxRetryAttempts: Int

        /// Timeout interval for network operations
        let timeoutInterval: TimeInterval

        /// Default configuration
        static let `default` = [SERVICE_NAME]Configuration(
            enableDebugLogging: false,
            maxRetryAttempts: 3,
            timeoutInterval: 30.0
        )
    }

    // MARK: - Errors

    /// Service-specific errors
    enum ServiceError: LocalizedError, Sendable {
        case invalidConfiguration
        case serviceNotRunning
        case operationFailed(String)
        case networkUnavailable
        case timeout

        var errorDescription: String? {
            switch self {
            case .invalidConfiguration:
                return "Invalid service configuration"
            case .serviceNotRunning:
                return "Service is not currently running"
            case .operationFailed(let message):
                return "Operation failed: \(message)"
            case .networkUnavailable:
                return "Network connection unavailable"
            case .timeout:
                return "Operation timed out"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize the service with configuration
    /// - Parameter configuration: Service configuration options
    init(configuration: [SERVICE_NAME]Configuration = .default) {
        self.configuration = configuration

        if configuration.enableDebugLogging {
            logger.info("[\(String(describing: Self.self))] Initialized with configuration: \(String(describing: configuration))")
        }
    }

    deinit {
        // Cleanup when service is deallocated
        backgroundTask?.cancel()
        logger.debug("[\(String(describing: Self.self))] Service deallocated")
    }

    // MARK: - Public Methods

    /// Start the service
    /// - Throws: ServiceError if startup fails
    func start() async throws {
        guard state == .idle || state == .error(_) else {
            logger.warning("[\(String(describing: Self.self))] Attempt to start service in invalid state: \(String(describing: state))")
            return
        }

        state = .starting
        logger.info("[\(String(describing: Self.self))] Starting service...")

        do {
            // Perform startup operations
            try await performStartup()

            // Start background operations
            startBackgroundOperations()

            state = .running
            logger.info("[\(String(describing: Self.self))] Service started successfully")

        } catch {
            state = .error(error)
            logger.error("[\(String(describing: Self.self))] Failed to start service: \(error.localizedDescription)")
            throw error
        }
    }

    /// Stop the service
    func stop() async {
        guard state == .running else {
            logger.warning("[\(String(describing: Self.self))] Attempt to stop service in invalid state: \(String(describing: state))")
            return
        }

        state = .stopping
        logger.info("[\(String(describing: Self.self))] Stopping service...")

        // Cancel background operations
        isCancelled = true
        backgroundTask?.cancel()
        backgroundTask = nil

        // Perform cleanup
        await performShutdown()

        state = .idle
        logger.info("[\(String(describing: Self.self))] Service stopped")
    }

    /// Perform a key operation of the service
    /// - Parameter [PARAMETER_NAME]: [PARAMETER_DESCRIPTION]
    /// - Returns: [RETURN_DESCRIPTION]
    /// - Throws: ServiceError if the operation fails
    func [OPERATION_NAME]([PARAMETER_NAME]: [PARAMETER_TYPE]) async throws -> [RETURN_TYPE] {
        guard state == .running else {
            throw ServiceError.serviceNotRunning
        }

        logger.debug("[\(String(describing: Self.self))] Performing [OPERATION_NAME] with parameter: \(String(describing: [PARAMETER_NAME]))")

        return try await withTimeout(configuration.timeoutInterval) {
            // Implement your operation here
            try await performOperation([PARAMETER_NAME])
        }
    }

    // MARK: - Private Methods

    /// Perform service startup operations
    private func performStartup() async throws {
        // Validate configuration
        guard configuration.maxRetryAttempts > 0 else {
            throw ServiceError.invalidConfiguration
        }

        // TODO: Add your startup logic here
        // Example: Initialize connections, load resources, etc.

        // Simulate startup delay
        if configuration.enableDebugLogging {
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Perform service shutdown operations
    private func performShutdown() async {
        // TODO: Add your cleanup logic here
        // Example: Close connections, save state, release resources

        logger.debug("[\(String(describing: Self.self))] Cleanup completed")
    }

    /// Start background operations
    private func startBackgroundOperations() {
        backgroundTask = Task { [weak self] in
            await self?.runBackgroundLoop()
        }
    }

    /// Background loop for continuous operations
    private func runBackgroundLoop() async {
        logger.debug("[\(String(describing: Self.self))] Background operations started")

        while !isCancelled && !Task.isCancelled {
            do {
                // TODO: Implement your background operations here
                // Example: Health checks, periodic updates, monitoring

                // Wait before next iteration
                try await Task.sleep(for: .seconds(1))

            } catch is CancellationError {
                break
            } catch {
                logger.error("[\(String(describing: Self.self))] Background operation error: \(error.localizedDescription)")

                // Wait before retrying
                try? await Task.sleep(for: .seconds(5))
            }
        }

        logger.debug("[\(String(describing: Self.self))] Background operations stopped")
    }

    /// Perform the core operation with retry logic
    private func performOperation(_ parameter: [PARAMETER_TYPE]) async throws -> [RETURN_TYPE] {
        var lastError: Error?

        for attempt in 1...configuration.maxRetryAttempts {
            do {
                // TODO: Implement your core operation logic here

                // Example operation - replace with your implementation
                logger.debug("[\(String(describing: Self.self))] Executing operation (attempt \(attempt)/\(configuration.maxRetryAttempts))")

                // Simulate work
                try await Task.sleep(for: .milliseconds(50))

                // Return result - replace with your actual result
                return [DEFAULT_RETURN_VALUE]

            } catch {
                lastError = error
                logger.warning("[\(String(describing: Self.self))] Operation attempt \(attempt) failed: \(error.localizedDescription)")

                // Don't retry on certain errors
                if error is CancellationError {
                    throw error
                }

                // Wait before retrying (exponential backoff)
                if attempt < configuration.maxRetryAttempts {
                    let delay = Double(attempt * attempt) * 0.5
                    try await Task.sleep(for: .seconds(delay))
                }
            }
        }

        // All retries failed
        let finalError = lastError ?? ServiceError.operationFailed("Unknown error")
        throw ServiceError.operationFailed("Operation failed after \(configuration.maxRetryAttempts) attempts: \(finalError.localizedDescription)")
    }

    /// Execute operation with timeout
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw ServiceError.timeout
            }

            // Return the first completed task and cancel others
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
}

// MARK: - Extensions

extension [SERVICE_NAME] {
    /// Check if the service is running
    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }

    /// Get current state description
    var stateDescription: String {
        switch state {
        case .idle:
            return "Idle"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .stopping:
            return "Stopping"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension [SERVICE_NAME] {
    /// Create a mock service for previews and testing
    static func mock() -> [SERVICE_NAME] {
        return [SERVICE_NAME](
            configuration: [SERVICE_NAME]Configuration(
                enableDebugLogging: true,
                maxRetryAttempts: 1,
                timeoutInterval: 5.0
            )
        )
    }
}
#endif

// MARK: - Template Placeholders
//
// Replace these placeholders when using this template:
//
// [SERVICE_NAME] - Name of your service class
// [PROJECT_NAME] - Name of your project
// [AUTHOR] - Author name
// [DATE] - Creation date
// [DESCRIPTION] - Brief description of the service
// [SERVICE_DESCRIPTION] - Detailed description of what the service does
// [CAPABILITY_1] - First main capability
// [CAPABILITY_2] - Second main capability
// [CAPABILITY_3] - Third main capability
// [BUNDLE_ID] - Your app's bundle identifier
// [OPERATION_NAME] - Name of the main operation method
// [PARAMETER_NAME] - Name of the operation parameter
// [PARAMETER_TYPE] - Type of the operation parameter
// [PARAMETER_DESCRIPTION] - Description of what the parameter does
// [RETURN_TYPE] - Return type of the operation
// [RETURN_DESCRIPTION] - Description of what is returned
// [DEFAULT_RETURN_VALUE] - Default return value for the template
//
// Example replacements:
// [SERVICE_NAME] -> VideoProcessingService
// [OPERATION_NAME] -> processVideo
// [PARAMETER_TYPE] -> URL
// [RETURN_TYPE] -> ProcessedVideo