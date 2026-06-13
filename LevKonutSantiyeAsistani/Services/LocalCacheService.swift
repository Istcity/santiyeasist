import Foundation

/// UserDefaults tabanlı API önbelleği — Free Tier limit koruması.
final class LocalCacheService {
    static let shared = LocalCacheService()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private struct Envelope<T: Codable>: Codable {
        let payload: T
        let fetchedAt: Date
    }

    // MARK: - Public API

    func save<T: Codable>(_ value: T, forKey key: String) {
        let envelope = Envelope(payload: value, fetchedAt: Date())
        guard let data = try? encoder.encode(envelope) else { return }
        defaults.set(data, forKey: key)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else {
            return nil
        }
        return envelope.payload
    }

    /// TTL geçerliyse önbelleği döndürür; değilse nil (yeni HTTP gerekir).
    func loadIfFresh<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        maxAge: TimeInterval
    ) -> T? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else {
            return nil
        }
        guard Date().timeIntervalSince(envelope.fetchedAt) < maxAge else {
            return nil
        }
        return envelope.payload
    }

    /// TTL dolmuş olsa bile veriyi döndürür (offline fallback).
    func loadStale<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        load(type, forKey: key)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Cache Keys

enum CacheKey {
    static let weather = "cache_weather_forecast"
    static let currency = "cache_currency_rates"
    static let materialPrices = "cache_material_prices"
    static let materialPricesFeed = "cache_material_prices_feed"
}

enum CacheTTL {
    static let weather: TimeInterval = 3600
    static let currency: TimeInterval = 12 * 3600
    static let materialPrices: TimeInterval = 3600
    /// Merkezi feed — saatlik yenileme.
    static let materialPricesFeed: TimeInterval = 3600
}
