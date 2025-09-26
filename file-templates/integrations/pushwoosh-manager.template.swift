import Foundation
import UserNotifications
import UIKit
import os.log

protocol PushNotificationManager {
    func initialize(appId: String, apiToken: String)
    func registerForNotifications()
    func handleDeviceTokenReceived(_ deviceToken: Data)
    func handleNotificationReceived(_ notification: UNNotification)
    func handleNotificationResponse(_ response: UNNotificationResponse)
    func sendTags(_ tags: [String: Any])
    func showInAppMessage(code: String)
}

final class PushwooshManager: NSObject, PushNotificationManager {
    static let shared = PushwooshManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "PushNotifications")
    private let baseURL = "https://cp.pushwoosh.com/json/1.3/"

    private var appId: String = ""
    private var apiToken: String = ""
    private var deviceToken: String?
    private var isInitialized = false

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    override private init() {
        super.init()
        setupNotificationCenter()
    }

    // MARK: - Public API

    func initialize(appId: String, apiToken: String) {
        guard !appId.isEmpty, !apiToken.isEmpty else {
            logger.error("Pushwoosh appId and apiToken are required")
            return
        }

        self.appId = appId
        self.apiToken = apiToken
        self.isInitialized = true

        logger.info("Pushwoosh initialized with appId: \(appId)")
        registerDevice()
    }

    func registerForNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { [weak self] granted, error in
            if let error = error {
                self?.logger.error("Notification authorization error: \(error)")
                return
            }

            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.logger.info("Notification authorization granted")
            } else {
                self?.logger.warning("Notification authorization denied")
            }
        }
    }

    func handleDeviceTokenReceived(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        logger.info("Device token received: \(token.prefix(8))...")

        if isInitialized {
            registerDevice()
        }
    }

    func handleNotificationReceived(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        logger.info("Notification received: \(notification.request.identifier)")

        // Extract Pushwoosh-specific data
        if let pushwooshData = userInfo["pw_msg"] as? [String: Any] {
            processPushwooshPayload(pushwooshData)
        }

        // Track notification delivery
        trackMessageDelivery(userInfo)
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        logger.info("Notification response: \(response.actionIdentifier)")

        // Handle deep links
        if let deepLink = userInfo["deep_link"] as? String {
            handleDeepLink(deepLink)
        }

        // Handle custom actions
        if response.actionIdentifier != UNNotificationDefaultActionIdentifier {
            handleCustomAction(response.actionIdentifier, userInfo: userInfo)
        }

        // Track notification open
        trackMessageOpen(userInfo)
    }

    func sendTags(_ tags: [String: Any]) {
        guard isInitialized else {
            logger.warning("Pushwoosh not initialized, cannot send tags")
            return
        }

        let request = PushwooshRequest(
            request: "setTags",
            application: appId,
            hwid: getHardwareId(),
            tags: tags
        )

        Task {
            await sendRequest(request)
        }
    }

    func showInAppMessage(code: String) {
        guard isInitialized else {
            logger.warning("Pushwoosh not initialized, cannot show in-app message")
            return
        }

        let request = PushwooshRequest(
            request: "getInAppMessage",
            application: appId,
            code: code,
            hwid: getHardwareId()
        )

        Task {
            await fetchAndShowInAppMessage(request)
        }
    }

    // MARK: - Private Methods

    private func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        if isInitialized {
            sendApplicationOpen()
        }
    }

    private func registerDevice() {
        guard let deviceToken = deviceToken else {
            logger.warning("Device token not available for registration")
            return
        }

        let request = PushwooshRequest(
            request: "registerDevice",
            application: appId,
            pushToken: deviceToken,
            hwid: getHardwareId(),
            deviceType: getDeviceType(),
            language: Locale.current.languageCode ?? "en"
        )

        Task {
            await sendRequest(request)
        }
    }

    private func sendApplicationOpen() {
        let request = PushwooshRequest(
            request: "applicationOpen",
            application: appId,
            hwid: getHardwareId()
        )

        Task {
            await sendRequest(request)
        }
    }

    private func sendRequest(_ request: PushwooshRequest) async {
        guard let url = URL(string: baseURL + request.request) else {
            logger.error("Invalid URL for request: \(request.request)")
            return
        }

        do {
            let requestData = try JSONEncoder().encode(request)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = requestData

            let (data, response) = try await session.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    logger.debug("Request \(request.request) successful")
                } else {
                    logger.error("Request \(request.request) failed with status: \(httpResponse.statusCode)")
                }
            }

            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Response: \(responseString)")
            }
        } catch {
            logger.error("Request \(request.request) error: \(error)")
        }
    }

    private func fetchAndShowInAppMessage(_ request: PushwooshRequest) async {
        guard let url = URL(string: baseURL + request.request) else { return }

        do {
            let requestData = try JSONEncoder().encode(request)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = requestData

            let (data, _) = try await session.data(for: urlRequest)
            let response = try JSONDecoder().decode(InAppMessageResponse.self, from: data)

            if let message = response.response {
                await showInAppMessageBanner(message)
            }
        } catch {
            logger.error("In-app message fetch error: \(error)")
        }
    }

    @MainActor
    private func showInAppMessageBanner(_ message: InAppMessage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        let bannerView = InAppMessageBanner(message: message)
        bannerView.frame = CGRect(
            x: 16,
            y: window.safeAreaInsets.top + 16,
            width: window.bounds.width - 32,
            height: 80
        )

        window.addSubview(bannerView)
        bannerView.show()

        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bannerView.hide()
        }
    }

    private func processPushwooshPayload(_ payload: [String: Any]) {
        // Handle rich notifications, badges, etc.
        if let badge = payload["badge"] as? Int {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = badge
            }
        }

        // Handle custom data
        if let customData = payload["custom"] as? [String: Any] {
            logger.debug("Custom notification data: \(customData)")
        }
    }

    private func handleDeepLink(_ deepLink: String) {
        guard let url = URL(string: deepLink) else { return }

        // Handle URL schemes or universal links
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func handleCustomAction(_ actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        logger.info("Custom action triggered: \(actionIdentifier)")

        // Handle custom notification actions
        switch actionIdentifier {
        case "VIEW_ACTION":
            // Handle view action
            break
        case "DISMISS_ACTION":
            // Handle dismiss action
            break
        default:
            break
        }
    }

    private func trackMessageDelivery(_ userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo["pw_msg_id"] as? String else { return }

        let request = PushwooshRequest(
            request: "messageDeliveryEvent",
            application: appId,
            hwid: getHardwareId(),
            messageId: messageId
        )

        Task {
            await sendRequest(request)
        }
    }

    private func trackMessageOpen(_ userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo["pw_msg_id"] as? String else { return }

        let request = PushwooshRequest(
            request: "pushStat",
            application: appId,
            hwid: getHardwareId(),
            messageId: messageId
        )

        Task {
            await sendRequest(request)
        }
    }

    private func getHardwareId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    private func getDeviceType() -> Int {
        #if os(visionOS)
        return 11 // VisionOS device type
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 4 : 1
        #else
        return 1
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushwooshManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleNotificationReceived(notification)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response)
        completionHandler()
    }
}

// MARK: - Data Models

private struct PushwooshRequest: Codable {
    let request: String
    let application: String?
    let pushToken: String?
    let hwid: String?
    let deviceType: Int?
    let language: String?
    let tags: [String: Any]?
    let code: String?
    let messageId: String?

    init(request: String, application: String? = nil, pushToken: String? = nil, hwid: String? = nil, deviceType: Int? = nil, language: String? = nil, tags: [String: Any]? = nil, code: String? = nil, messageId: String? = nil) {
        self.request = request
        self.application = application
        self.pushToken = pushToken
        self.hwid = hwid
        self.deviceType = deviceType
        self.language = language
        self.tags = tags
        self.code = code
        self.messageId = messageId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request, forKey: .request)
        try container.encodeIfPresent(application, forKey: .application)
        try container.encodeIfPresent(pushToken, forKey: .pushToken)
        try container.encodeIfPresent(hwid, forKey: .hwid)
        try container.encodeIfPresent(deviceType, forKey: .deviceType)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(messageId, forKey: .messageId)

        if let tags = tags {
            try container.encode(AnyCodable(tags), forKey: .tags)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case request
        case application
        case pushToken = "push_token"
        case hwid
        case deviceType = "device_type"
        case language
        case tags
        case code
        case messageId = "message_id"
    }
}

private struct InAppMessageResponse: Codable {
    let response: InAppMessage?
}

private struct InAppMessage: Codable {
    let title: String
    let message: String
    let imageUrl: String?
    let actionUrl: String?

    private enum CodingKeys: String, CodingKey {
        case title
        case message
        case imageUrl = "image_url"
        case actionUrl = "action_url"
    }
}

// MARK: - In-App Message Banner

private class InAppMessageBanner: UIView {
    private let message: InAppMessage
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let closeButton = UIButton()

    init(message: InAppMessage) {
        self.message = message
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.1

        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(closeButton)

        titleLabel.text = message.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 1

        messageLabel.text = message.message
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.numberOfLines = 2
        messageLabel.textColor = UIColor.secondaryLabel

        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(UIColor.label, for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func show() {
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -bounds.height)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -self.bounds.height)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    @objc private func closeTapped() {
        hide()
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