import Foundation
import Combine
import os.log

protocol ConfigurationService {
    func loadConfiguration() async throws
    func getValue<T: Codable>(for key: String, type: T.Type, defaultValue: T?) -> T?
    func refreshConfiguration() async throws
    func addConfigurationObserver(_ observer: ConfigurationObserver)
    func removeConfigurationObserver(_ observer: ConfigurationObserver)
}

protocol ConfigurationObserver: AnyObject {
    func configurationDidUpdate(_ config: [String: Any])
    func configurationDidFailToLoad(_ error: Error)
}

enum ConfigurationError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(Error)
    case fileNotFound
    case invalidFormat
    case versionMismatch

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid configuration URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let error):
            return "Parsing error: \(error.localizedDescription)"
        case .fileNotFound:
            return "Configuration file not found"
        case .invalidFormat:
            return "Invalid configuration format"
        case .versionMismatch:
            return "Configuration version mismatch"
        }
    }
}

@MainActor
final class JSONConfigurationManager: ObservableObject, ConfigurationService {
    static let shared = JSONConfigurationManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Configuration")

    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var configVersion: String?

    private var configuration: [String: Any] = [:]
    private var observers: [WeakObserver] = []

    // Configuration sources
    private var remoteURL: URL?
    private var localFallbackURL: URL?
    private let userDefaults = UserDefaults.standard
    private let configurationKey = "cached_configuration"
    private let versionKey = "configuration_version"
    private let lastUpdateKey = "configuration_last_update"

    // Hot reload support
    private var reloadTimer: Timer?
    private let reloadInterval: TimeInterval
    private var lastModificationDate: Date?

    // Network session
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private init(reloadInterval: TimeInterval = 300) { // 5 minutes default
        self.reloadInterval = reloadInterval
        loadLocalFallback()
        loadCachedConfiguration()
        setupHotReload()
    }

    deinit {
        reloadTimer?.invalidate()
    }

    // MARK: - Public API

    func configure(remoteURL: URL?, localFallbackPath: String? = nil, enableHotReload: Bool = true) {
        self.remoteURL = remoteURL

        if let localPath = localFallbackPath {
            self.localFallbackURL = Bundle.main.url(forResource: localPath, withExtension: "json")
        }

        if enableHotReload {
            setupHotReload()
        } else {
            reloadTimer?.invalidate()
        }

        logger.info("Configuration manager configured with remote URL: \(remoteURL?.absoluteString ?? "none")")
    }

    func loadConfiguration() async throws {
        isLoading = true
        defer { isLoading = false }

        logger.info("Loading configuration")

        do {
            // Try remote configuration first
            if let remoteURL = remoteURL {
                try await loadRemoteConfiguration(from: remoteURL)
                return
            }

            // Fall back to local configuration
            try loadLocalFallback()

        } catch {
            logger.error("Failed to load configuration: \(error)")

            // Try cached configuration as last resort
            if !configuration.isEmpty {
                logger.info("Using cached configuration")
                return
            }

            throw error
        }
    }

    func getValue<T: Codable>(for key: String, type: T.Type, defaultValue: T? = nil) -> T? {
        let value = getValue(for: key)

        if let value = value {
            // Try direct type match first
            if let typedValue = value as? T {
                return typedValue
            }

            // Try JSON decoding for complex types
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                logger.warning("Failed to decode value for key '\(key)': \(error)")
            }
        }

        return defaultValue
    }

    func refreshConfiguration() async throws {
        logger.info("Refreshing configuration")
        try await loadConfiguration()
    }

    func addConfigurationObserver(_ observer: ConfigurationObserver) {
        observers.append(WeakObserver(observer))
        cleanupObservers()
    }

    func removeConfigurationObserver(_ observer: ConfigurationObserver) {
        observers.removeAll { $0.observer === observer }
    }

    // MARK: - Private Methods

    private func loadRemoteConfiguration(from url: URL) async throws {
        logger.debug("Loading remote configuration from: \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(from: url)

            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw ConfigurationError.networkError(URLError(.badServerResponse))
                }

                // Check for modification date
                if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified"),
                   let modificationDate = DateFormatter.httpDate.date(from: lastModified) {

                    if let cachedDate = lastModificationDate,
                       modificationDate <= cachedDate {
                        logger.debug("Remote configuration not modified, using cached version")
                        return
                    }

                    lastModificationDate = modificationDate
                }
            }

            try await parseConfiguration(data)
            cacheConfiguration(data)

        } catch {
            throw ConfigurationError.networkError(error)
        }
    }

    private func loadLocalFallback() throws {
        guard let localURL = localFallbackURL else {
            throw ConfigurationError.fileNotFound
        }

        logger.debug("Loading local fallback configuration")

        do {
            let data = try Data(contentsOf: localURL)
            try parseConfigurationSync(data)
        } catch {
            throw ConfigurationError.parsingError(error)
        }
    }

    private func loadCachedConfiguration() {
        if let cachedData = userDefaults.data(forKey: configurationKey) {
            do {
                try parseConfigurationSync(cachedData)
                configVersion = userDefaults.string(forKey: versionKey)
                lastUpdated = userDefaults.object(forKey: lastUpdateKey) as? Date
                logger.info("Loaded cached configuration")
            } catch {
                logger.error("Failed to load cached configuration: \(error)")
            }
        }
    }

    private func parseConfiguration(_ data: Data) async throws {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])

            guard let configDict = json as? [String: Any] else {
                throw ConfigurationError.invalidFormat
            }

            await MainActor.run {
                self.configuration = configDict
                self.lastUpdated = Date()

                // Extract version if present
                if let version = configDict["version"] as? String {
                    self.configVersion = version
                }
            }

            notifyObservers(configDict)
            logger.info("Configuration parsed successfully")

        } catch {
            throw ConfigurationError.parsingError(error)
        }
    }

    private func parseConfigurationSync(_ data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        guard let configDict = json as? [String: Any] else {
            throw ConfigurationError.invalidFormat
        }

        configuration = configDict
        lastUpdated = Date()

        if let version = configDict["version"] as? String {
            configVersion = version
        }
    }

    private func cacheConfiguration(_ data: Data) {
        userDefaults.set(data, forKey: configurationKey)
        userDefaults.set(configVersion, forKey: versionKey)
        userDefaults.set(lastUpdated, forKey: lastUpdateKey)
        logger.debug("Configuration cached")
    }

    private func getValue(for key: String) -> Any? {
        // Support nested keys with dot notation (e.g., "feature.enabled")
        let components = key.split(separator: ".").map(String.init)
        var current: Any = configuration

        for component in components {
            guard let dict = current as? [String: Any],
                  let value = dict[component] else {
                return nil
            }
            current = value
        }

        return current
    }

    private func setupHotReload() {
        guard reloadInterval > 0 else { return }

        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: reloadInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try? await self?.refreshConfiguration()
            }
        }

        logger.debug("Hot reload enabled with interval: \(reloadInterval)s")
    }

    private func notifyObservers(_ config: [String: Any]) {
        cleanupObservers()

        for weakObserver in observers {
            weakObserver.observer?.configurationDidUpdate(config)
        }
    }

    private func notifyObserversOfError(_ error: Error) {
        cleanupObservers()

        for weakObserver in observers {
            weakObserver.observer?.configurationDidFailToLoad(error)
        }
    }

    private func cleanupObservers() {
        observers.removeAll { $0.observer == nil }
    }
}

// MARK: - Configuration Extensions

extension JSONConfigurationManager {
    // Convenience methods for common types
    func getString(for key: String, defaultValue: String = "") -> String {
        return getValue(for: key, type: String.self, defaultValue: defaultValue) ?? defaultValue
    }

    func getBool(for key: String, defaultValue: Bool = false) -> Bool {
        return getValue(for: key, type: Bool.self, defaultValue: defaultValue) ?? defaultValue
    }

    func getInt(for key: String, defaultValue: Int = 0) -> Int {
        return getValue(for: key, type: Int.self, defaultValue: defaultValue) ?? defaultValue
    }

    func getDouble(for key: String, defaultValue: Double = 0.0) -> Double {
        return getValue(for: key, type: Double.self, defaultValue: defaultValue) ?? defaultValue
    }

    func getArray<T: Codable>(for key: String, type: T.Type) -> [T]? {
        return getValue(for: key, type: [T].self)
    }

    func getDictionary(for key: String) -> [String: Any]? {
        return getValue(for: key) as? [String: Any]
    }

    // Feature flags
    func isFeatureEnabled(_ feature: String) -> Bool {
        return getBool(for: "features.\(feature).enabled", defaultValue: false)
    }

    func getFeatureConfig<T: Codable>(_ feature: String, type: T.Type) -> T? {
        return getValue(for: "features.\(feature).config", type: type)
    }

    // Environment-specific configuration
    func getEnvironmentValue<T: Codable>(for key: String, type: T.Type, defaultValue: T? = nil) -> T? {
        let environment = getCurrentEnvironment()
        let envKey = "environments.\(environment).\(key)"

        return getValue(for: envKey, type: type, defaultValue: defaultValue)
    }

    private func getCurrentEnvironment() -> String {
        #if DEBUG
        return "development"
        #elseif STAGING
        return "staging"
        #else
        return "production"
        #endif
    }
}

// MARK: - Reactive Configuration

extension JSONConfigurationManager {
    func publisher<T: Codable>(for key: String, type: T.Type, defaultValue: T? = nil) -> AnyPublisher<T?, Never> {
        return NotificationCenter.default
            .publisher(for: .configurationDidUpdate)
            .map { [weak self] _ in
                return self?.getValue(for: key, type: type, defaultValue: defaultValue)
            }
            .prepend(getValue(for: key, type: type, defaultValue: defaultValue))
            .eraseToAnyPublisher()
    }
}

// MARK: - Helper Types

private class WeakObserver {
    weak var observer: ConfigurationObserver?

    init(_ observer: ConfigurationObserver) {
        self.observer = observer
    }
}

private extension DateFormatter {
    static let httpDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

private extension Notification.Name {
    static let configurationDidUpdate = Notification.Name("ConfigurationDidUpdate")
}

// MARK: - Configuration Models

struct AppConfiguration: Codable {
    let version: String
    let features: FeatureFlags
    let api: APIConfiguration
    let ui: UIConfiguration
    let analytics: AnalyticsConfiguration?

    struct FeatureFlags: Codable {
        let darkMode: FeatureFlag
        let pushNotifications: FeatureFlag
        let premiumFeatures: FeatureFlag
        let experimentalUI: FeatureFlag
    }

    struct FeatureFlag: Codable {
        let enabled: Bool
        let rolloutPercentage: Double?
        let config: [String: AnyCodableValue]?
    }

    struct APIConfiguration: Codable {
        let baseURL: String
        let timeout: TimeInterval
        let retryCount: Int
        let apiKey: String?
    }

    struct UIConfiguration: Codable {
        let theme: String
        let animations: Bool
        let haptics: Bool
        let sounds: Bool
    }

    struct AnalyticsConfiguration: Codable {
        let enabled: Bool
        let samplingRate: Double
        let debugMode: Bool
    }
}

struct AnyCodableValue: Codable {
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
            try container.encode(array.map(AnyCodableValue.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodableValue.init))
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
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
}

// MARK: - Usage Example

/*
// Configuration setup in AppDelegate or App struct:
let configManager = JSONConfigurationManager.shared
configManager.configure(
    remoteURL: URL(string: "https://api.example.com/config"),
    localFallbackPath: "config",
    enableHotReload: true
)

// Load configuration on app start:
Task {
    try await configManager.loadConfiguration()
}

// Using configuration values:
let apiBaseURL = configManager.getString(for: "api.baseURL", defaultValue: "https://api.example.com")
let isFeatureEnabled = configManager.isFeatureEnabled("darkMode")
let timeout = configManager.getDouble(for: "api.timeout", defaultValue: 30.0)

// Observing configuration changes:
class MyViewController: UIViewController, ConfigurationObserver {
    override func viewDidLoad() {
        super.viewDidLoad()
        JSONConfigurationManager.shared.addConfigurationObserver(self)
    }

    func configurationDidUpdate(_ config: [String: Any]) {
        // Update UI or refresh data
        updateUI()
    }

    func configurationDidFailToLoad(_ error: Error) {
        // Handle configuration load error
        showError(error)
    }
}

// Using typed configuration models:
let appConfig: AppConfiguration? = configManager.getValue(for: "", type: AppConfiguration.self)
*/