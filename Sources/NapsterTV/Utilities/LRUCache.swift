import Foundation

// 线程安全的 LRU 缓存
final class LRUCache<Key: Hashable, Value> {
    private var cache: [Key: Value] = [:]
    private var order: [Key] = []
    private let maxSize: Int
    private let lock = NSLock()

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let value = cache[key] else { return nil }
        // LRU：移到最后
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    func set(_ key: Key, value: Value) {
        lock.lock()
        defer { lock.unlock() }

        if cache[key] != nil {
            order.removeAll { $0 == key }
        }
        cache[key] = value
        order.append(key)

        // 超出容量时淘汰最旧
        while order.count > maxSize {
            let oldest = order.removeFirst()
            cache.removeValue(forKey: oldest)
        }
    }

    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: key)
        order.removeAll { $0 == key }
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        order.removeAll()
    }
}

// 带过期时间的缓存条目
struct TimedCacheEntry<T> {
    let expiresAt: Date
    let data: T

    var isExpired: Bool {
        Date() > expiresAt
    }
}
