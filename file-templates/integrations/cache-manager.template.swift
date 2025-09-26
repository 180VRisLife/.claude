import Foundation
import CryptoKit
import os.log

protocol CacheManager {
    func store<T: Codable>(_ object: T, forKey key: String, expiration: CacheExpiration?) async throws
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    func remove(forKey key: String) async throws
    func removeAll() async throws
    func removeExpired() async throws
    func cacheSize() async -> Int64
}

enum CacheError: LocalizedError {
    case keyNotFound
    case dataCorrupted
    case encodingFailed
    case decodingFailed
    case diskWriteFailed
    case diskReadFailed
    case invalidExpiration

    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "Cache key not found"
        case .dataCorrupted:
            return "Cached data is corrupted"
        case .encodingFailed:
            return "Failed to encode object"
        case .decodingFailed:
            return "Failed to decode object"
        case .diskWriteFailed:
            return "Failed to write to disk"
        case .diskReadFailed:
            return "Failed to read from disk"
        case .invalidExpiration:
            return "Invalid expiration date"
        }
    }
}

enum CacheExpiration {
    case never
    case seconds(TimeInterval)
    case date(Date)

    var expirationDate: Date? {
        switch self {
        case .never:
            return nil
        case .seconds(let interval):
            return Date().addingTimeInterval(interval)
        case .date(let date):
            return date
        }
    }
}

actor AdvancedCacheManager: CacheManager {
    static let shared = AdvancedCacheManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "CacheManager")

    // Memory cache
    private var memoryCache: [String: CacheItem] = [:]
    private var memoryAccessOrder: [String] = []
    private let maxMemoryItems: Int
    private let maxMemorySize: Int64

    // Disk cache
    private let diskCacheDirectory: URL
    private let fileManager = FileManager.default
    private let maxDiskSize: Int64

    // Background cleanup
    private var cleanupTimer: Timer?
    private let cleanupInterval: TimeInterval = 300 // 5 minutes

    private init(
        maxMemoryItems: Int = 100,
        maxMemorySize: Int64 = 50 * 1024 * 1024, // 50MB
        maxDiskSize: Int64 = 500 * 1024 * 1024 // 500MB
    ) {
        self.maxMemoryItems = maxMemoryItems
        self.maxMemorySize = maxMemorySize
        self.maxDiskSize = maxDiskSize

        // Setup disk cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheDirectory = cacheDir.appendingPathComponent("AdvancedCache", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)

        // Start cleanup timer
        setupCleanupTimer()

        logger.info("Cache manager initialized with memory limit: \(maxMemoryItems) items, \(maxMemorySize) bytes")
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - Public API

    func store<T: Codable>(_ object: T, forKey key: String, expiration: CacheExpiration? = nil) async throws {
        logger.debug("Storing object for key: \(key)")

        guard !key.isEmpty else {
            throw CacheError.keyNotFound
        }

        do {
            let data = try JSONEncoder().encode(object)
            let item = CacheItem(
                key: key,
                data: data,
                expirationDate: expiration?.expirationDate,
                accessCount: 1,
                lastAccessed: Date(),
                size: Int64(data.count)
            )

            // Store in memory cache
            await storeInMemory(item)

            // Store on disk
            try await storeToDisk(item)

        } catch {
            logger.error("Failed to store object for key \(key): \(error)")
            throw CacheError.encodingFailed
        }
    }

    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        logger.debug("Retrieving object for key: \(key)")

        guard !key.isEmpty else {
            throw CacheError.keyNotFound
        }

        // Try memory cache first
        if let item = memoryCache[key] {
            if await isExpired(item) {
                await removeFromMemory(key)
                try await removeFromDisk(key)
                return nil
            }

            // Update access tracking
            await updateAccess(for: key)

            do {
                let object = try JSONDecoder().decode(type, from: item.data)
                return object
            } catch {
                logger.error("Failed to decode object from memory for key \(key): \(error)")
                throw CacheError.decodingFailed
            }
        }

        // Try disk cache
        do {
            if let item = try await retrieveFromDisk(key) {
                if await isExpired(item) {
                    try await removeFromDisk(key)
                    return nil
                }

                // Move to memory cache
                await storeInMemory(item)

                let object = try JSONDecoder().decode(type, from: item.data)
                return object
            }
        } catch {
            logger.error("Failed to retrieve object from disk for key \(key): \(error)")
            throw CacheError.diskReadFailed
        }

        return nil
    }

    func remove(forKey key: String) async throws {
        logger.debug("Removing object for key: \(key)")

        await removeFromMemory(key)
        try await removeFromDisk(key)
    }

    func removeAll() async throws {
        logger.info("Removing all cached objects")

        // Clear memory cache
        memoryCache.removeAll()
        memoryAccessOrder.removeAll()

        // Clear disk cache
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            logger.error("Failed to clear disk cache: \(error)")
            throw CacheError.diskWriteFailed
        }
    }

    func removeExpired() async throws {
        logger.debug("Removing expired objects")

        // Remove expired from memory
        var expiredKeys: [String] = []
        for (key, item) in memoryCache {
            if await isExpired(item) {
                expiredKeys.append(key)
            }
        }

        for key in expiredKeys {
            await removeFromMemory(key)
        }

        // Remove expired from disk
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])

            for url in contents {
                if let item = try await retrieveFromDisk(url.lastPathComponent),
                   await isExpired(item) {
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            logger.error("Failed to remove expired disk items: \(error)")
        }
    }

    func cacheSize() async -> Int64 {
        let memorySize = memoryCache.values.reduce(0) { $0 + $1.size }

        let diskSize: Int64
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            diskSize = contents.reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(size)
            }
        } catch {
            diskSize = 0
        }

        return memorySize + diskSize
    }

    // MARK: - Memory Cache Management

    private func storeInMemory(_ item: CacheItem) async {
        // Remove existing item if present
        if memoryCache[item.key] != nil {
            await removeFromMemory(item.key)
        }

        // Add new item
        memoryCache[item.key] = item
        memoryAccessOrder.append(item.key)

        // Enforce memory limits
        await enforceMemoryLimits()
    }

    private func removeFromMemory(_ key: String) async {
        memoryCache.removeValue(forKey: key)
        memoryAccessOrder.removeAll { $0 == key }
    }

    private func updateAccess(for key: String) async {
        if var item = memoryCache[key] {
            item.accessCount += 1
            item.lastAccessed = Date()
            memoryCache[key] = item

            // Move to end of access order (most recently used)
            memoryAccessOrder.removeAll { $0 == key }
            memoryAccessOrder.append(key)
        }
    }

    private func enforceMemoryLimits() async {
        // Enforce item count limit (LRU eviction)
        while memoryCache.count > maxMemoryItems {
            if let lruKey = memoryAccessOrder.first {
                await removeFromMemory(lruKey)
            }
        }

        // Enforce size limit (LRU eviction)
        var currentSize = memoryCache.values.reduce(0) { $0 + $1.size }
        while currentSize > maxMemorySize && !memoryCache.isEmpty {
            if let lruKey = memoryAccessOrder.first {
                if let item = memoryCache[lruKey] {
                    currentSize -= item.size
                }
                await removeFromMemory(lruKey)
            }
        }
    }

    // MARK: - Disk Cache Management

    private func storeToDisk(_ item: CacheItem) async throws {
        let filename = hashKey(item.key)
        let fileURL = diskCacheDirectory.appendingPathComponent(filename)

        do {
            let cacheData = try JSONEncoder().encode(item)
            try cacheData.write(to: fileURL)
        } catch {
            logger.error("Failed to write to disk: \(error)")
            throw CacheError.diskWriteFailed
        }

        // Enforce disk size limits
        await enforceDiskLimits()
    }

    private func retrieveFromDisk(_ key: String) async throws -> CacheItem? {
        let filename = hashKey(key)
        let fileURL = diskCacheDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let item = try JSONDecoder().decode(CacheItem.self, from: data)
            return item
        } catch {
            logger.error("Failed to read from disk: \(error)")
            throw CacheError.diskReadFailed
        }
    }

    private func removeFromDisk(_ key: String) async throws {
        let filename = hashKey(key)
        let fileURL = diskCacheDirectory.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    private func enforceDiskLimits() async {
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])

            let fileInfos = contents.compactMap { url -> (URL, Int64, Date)? in
                guard let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                      let size = resourceValues.fileSize,
                      let date = resourceValues.contentModificationDate else {
                    return nil
                }
                return (url, Int64(size), date)
            }

            let totalSize = fileInfos.reduce(0) { $0 + $1.1 }

            if totalSize > maxDiskSize {
                // Sort by modification date (oldest first)
                let sortedFiles = fileInfos.sorted { $0.2 < $1.2 }
                var sizeToRemove = totalSize - maxDiskSize

                for (url, size, _) in sortedFiles {
                    if sizeToRemove <= 0 { break }
                    try fileManager.removeItem(at: url)
                    sizeToRemove -= size
                }
            }
        } catch {
            logger.error("Failed to enforce disk limits: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func hashKey(_ key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isExpired(_ item: CacheItem) async -> Bool {
        guard let expirationDate = item.expirationDate else {
            return false // Never expires
        }
        return Date() > expirationDate
    }

    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.removeExpired()
            }
        }
    }
}

// MARK: - Data Models

private struct CacheItem: Codable {
    let key: String
    let data: Data
    let expirationDate: Date?
    var accessCount: Int
    var lastAccessed: Date
    let size: Int64

    enum CodingKeys: String, CodingKey {
        case key
        case data
        case expirationDate = "expiration_date"
        case accessCount = "access_count"
        case lastAccessed = "last_accessed"
        case size
    }
}

// MARK: - Convenience Extensions

extension AdvancedCacheManager {
    // Store with TTL in seconds
    func store<T: Codable>(_ object: T, forKey key: String, ttl: TimeInterval) async throws {
        try await store(object, forKey: key, expiration: .seconds(ttl))
    }

    // Store image data
    func storeImage(_ imageData: Data, forKey key: String, expiration: CacheExpiration? = nil) async throws {
        struct ImageWrapper: Codable {
            let data: Data
        }
        try await store(ImageWrapper(data: imageData), forKey: key, expiration: expiration)
    }

    // Retrieve image data
    func retrieveImageData(forKey key: String) async throws -> Data? {
        struct ImageWrapper: Codable {
            let data: Data
        }
        let wrapper: ImageWrapper? = try await retrieve(ImageWrapper.self, forKey: key)
        return wrapper?.data
    }

    // Batch operations
    func storeBatch<T: Codable>(_ objects: [(T, String)], expiration: CacheExpiration? = nil) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (object, key) in objects {
                group.addTask {
                    try await self.store(object, forKey: key, expiration: expiration)
                }
            }
            try await group.waitForAll()
        }
    }

    func retrieveBatch<T: Codable>(_ type: T.Type, forKeys keys: [String]) async throws -> [String: T] {
        return try await withThrowingTaskGroup(of: (String, T?).self, returning: [String: T].self) { group in
            for key in keys {
                group.addTask {
                    let object = try await self.retrieve(type, forKey: key)
                    return (key, object)
                }
            }

            var results: [String: T] = [:]
            for try await (key, object) in group {
                if let object = object {
                    results[key] = object
                }
            }
            return results
        }
    }
}

// MARK: - Cache Statistics

extension AdvancedCacheManager {
    struct CacheStats {
        let memoryItemCount: Int
        let diskItemCount: Int
        let totalSize: Int64
        let hitRate: Double
    }

    private var hitCount: Int = 0
    private var missCount: Int = 0

    func getCacheStats() async -> CacheStats {
        let memoryItemCount = memoryCache.count

        let diskItemCount: Int
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil)
            diskItemCount = contents.count
        } catch {
            diskItemCount = 0
        }

        let totalSize = await cacheSize()
        let hitRate = Double(hitCount) / Double(hitCount + missCount)

        return CacheStats(
            memoryItemCount: memoryItemCount,
            diskItemCount: diskItemCount,
            totalSize: totalSize,
            hitRate: hitRate.isNaN ? 0.0 : hitRate
        )
    }
}