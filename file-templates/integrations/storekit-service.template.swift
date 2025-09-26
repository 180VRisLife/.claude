import Foundation
import StoreKit
import os.log

protocol InAppPurchaseService {
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Transaction?
    func restorePurchases() async throws
    func validateReceipt() async throws -> Bool
    func checkSubscriptionStatus() async -> SubscriptionStatus
}

enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case receiptValidationFailed
    case networkError
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .receiptValidationFailed:
            return "Receipt validation failed"
        case .networkError:
            return "Network error occurred"
        case .userCancelled:
            return "Purchase cancelled by user"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

enum SubscriptionStatus {
    case notSubscribed
    case subscribed(Product)
    case expired(Product)
    case inGracePeriod(Product)
    case inBillingRetryPeriod(Product)
}

@MainActor
final class StoreKitService: NSObject, ObservableObject, InAppPurchaseService {
    static let shared = StoreKitService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "StoreKit")

    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed

    private var productIds: Set<String> = []
    private var transactionUpdateTask: Task<Void, Never>?

    private let receiptValidator = ReceiptValidator()

    override private init() {
        super.init()
        startTransactionListener()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Configuration

    func configure(productIds: [String]) {
        self.productIds = Set(productIds)
        logger.info("StoreKit configured with \(productIds.count) products")

        Task {
            try await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Public API

    func loadProducts() async throws -> [Product] {
        guard !productIds.isEmpty else {
            logger.error("Product IDs not configured")
            throw PurchaseError.productNotFound
        }

        do {
            let products = try await Product.products(for: productIds)
            await MainActor.run {
                self.products = products
            }
            logger.info("Loaded \(products.count) products")
            return products
        } catch {
            logger.error("Failed to load products: \(error)")
            throw PurchaseError.networkError
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        logger.info("Attempting to purchase: \(product.id)")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                await updatePurchasedProducts()
                logger.info("Purchase successful: \(product.id)")
                return transaction

            case .userCancelled:
                logger.info("Purchase cancelled by user: \(product.id)")
                throw PurchaseError.userCancelled

            case .pending:
                logger.info("Purchase pending: \(product.id)")
                return nil

            @unknown default:
                logger.error("Unknown purchase result: \(product.id)")
                throw PurchaseError.unknown
            }
        } catch {
            logger.error("Purchase failed: \(error)")
            if error is PurchaseError {
                throw error
            } else {
                throw PurchaseError.purchaseFailed(error.localizedDescription)
            }
        }
    }

    func restorePurchases() async throws {
        logger.info("Restoring purchases")

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            logger.info("Purchases restored successfully")
        } catch {
            logger.error("Failed to restore purchases: \(error)")
            throw PurchaseError.networkError
        }
    }

    func validateReceipt() async throws -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            logger.error("Receipt not found")
            throw PurchaseError.receiptValidationFailed
        }

        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let isValid = try await receiptValidator.validate(receiptData)
            logger.info("Receipt validation result: \(isValid)")
            return isValid
        } catch {
            logger.error("Receipt validation failed: \(error)")
            throw PurchaseError.receiptValidationFailed
        }
    }

    func checkSubscriptionStatus() async -> SubscriptionStatus {
        logger.debug("Checking subscription status")

        // Get subscription products
        let subscriptionProducts = products.filter { $0.type == .autoRenewable }

        for product in subscriptionProducts {
            if let status = await product.subscription?.status.first {
                switch status.state {
                case .subscribed:
                    await MainActor.run {
                        self.subscriptionStatus = .subscribed(product)
                    }
                    return .subscribed(product)

                case .expired:
                    await MainActor.run {
                        self.subscriptionStatus = .expired(product)
                    }
                    return .expired(product)

                case .inGracePeriod:
                    await MainActor.run {
                        self.subscriptionStatus = .inGracePeriod(product)
                    }
                    return .inGracePeriod(product)

                case .inBillingRetryPeriod:
                    await MainActor.run {
                        self.subscriptionStatus = .inBillingRetryPeriod(product)
                    }
                    return .inBillingRetryPeriod(product)

                case .revoked:
                    break

                @unknown default:
                    break
                }
            }
        }

        await MainActor.run {
            self.subscriptionStatus = .notSubscribed
        }
        return .notSubscribed
    }

    // MARK: - Private Methods

    private func startTransactionListener() {
        transactionUpdateTask = Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await updatePurchasedProducts()
                    logger.info("Transaction updated: \(transaction.productID)")
                } catch {
                    logger.error("Transaction update error: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            logger.error("Transaction verification failed")
            throw PurchaseError.receiptValidationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProducts.insert(transaction.productID)
            } catch {
                logger.error("Failed to verify entitlement: \(error)")
            }
        }

        await MainActor.run {
            self.purchasedProducts = purchasedProducts
        }

        await checkSubscriptionStatus()
    }

    // MARK: - Product Helpers

    func product(for id: String) -> Product? {
        return products.first { $0.id == id }
    }

    func isPurchased(_ productId: String) -> Bool {
        return purchasedProducts.contains(productId)
    }

    func isSubscriptionActive() -> Bool {
        switch subscriptionStatus {
        case .subscribed, .inGracePeriod:
            return true
        case .notSubscribed, .expired, .inBillingRetryPeriod:
            return false
        }
    }
}

// MARK: - Receipt Validator

private class ReceiptValidator {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "ReceiptValidator")

    #if DEBUG
    private let verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt"
    #else
    private let verifyReceiptURL = "https://buy.itunes.apple.com/verifyReceipt"
    #endif

    func validate(_ receiptData: Data) async throws -> Bool {
        let receiptString = receiptData.base64EncodedString()

        let requestBody: [String: Any] = [
            "receipt-data": receiptString,
            "password": getSharedSecret() ?? "",
            "exclude-old-transactions": true
        ]

        guard let url = URL(string: verifyReceiptURL),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw PurchaseError.receiptValidationFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                logger.error("Receipt validation HTTP error")
                throw PurchaseError.receiptValidationFailed
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let status = json?["status"] as? Int

            switch status {
            case 0:
                logger.info("Receipt validation successful")
                return true
            case 21007:
                // Sandbox receipt sent to production
                logger.warning("Sandbox receipt sent to production, retrying...")
                return try await validateSandboxReceipt(receiptData)
            default:
                logger.error("Receipt validation failed with status: \(status ?? -1)")
                return false
            }
        } catch {
            logger.error("Receipt validation network error: \(error)")
            throw PurchaseError.networkError
        }
    }

    private func validateSandboxReceipt(_ receiptData: Data) async throws -> Bool {
        let sandboxURL = "https://sandbox.itunes.apple.com/verifyReceipt"
        let receiptString = receiptData.base64EncodedString()

        let requestBody: [String: Any] = [
            "receipt-data": receiptString,
            "password": getSharedSecret() ?? "",
            "exclude-old-transactions": true
        ]

        guard let url = URL(string: sandboxURL),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw PurchaseError.receiptValidationFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let status = json?["status"] as? Int

        return status == 0
    }

    private func getSharedSecret() -> String? {
        // Return your App Store Connect shared secret
        // This should be stored securely, preferably in Keychain
        return Bundle.main.object(forInfoDictionaryKey: "APP_STORE_SHARED_SECRET") as? String
    }
}

// MARK: - Product Extensions

extension Product {
    var localizedPrice: String {
        return priceFormatStyle.format(price)
    }

    var subscriptionPeriod: String? {
        guard let subscription = subscription,
              let period = subscription.subscriptionPeriod else {
            return nil
        }

        switch period.unit {
        case .day:
            return period.value == 1 ? "Daily" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "Weekly" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "Monthly" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "Yearly" : "\(period.value) years"
        @unknown default:
            return nil
        }
    }

    var hasFreeTrial: Bool {
        return subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    var freeTrialPeriod: String? {
        guard let introOffer = subscription?.introductoryOffer,
              introOffer.paymentMode == .freeTrial,
              let period = introOffer.period else {
            return nil
        }

        switch period.unit {
        case .day:
            return "\(period.value) day\(period.value > 1 ? "s" : "")"
        case .week:
            return "\(period.value) week\(period.value > 1 ? "s" : "")"
        case .month:
            return "\(period.value) month\(period.value > 1 ? "s" : "")"
        case .year:
            return "\(period.value) year\(period.value > 1 ? "s" : "")"
        @unknown default:
            return nil
        }
    }
}

// MARK: - Purchase Manager

class PurchaseManager: ObservableObject {
    private let storeKit = StoreKitService.shared

    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadProducts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            _ = try await storeKit.loadProducts()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func purchase(_ product: Product) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            _ = try await storeKit.purchase(product)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func restorePurchases() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try await storeKit.restorePurchases()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
}