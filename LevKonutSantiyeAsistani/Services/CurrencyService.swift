import Foundation

/// ExchangeRate-API — UserDefaults önbellek, 12 saatte en fazla 1 HTTP isteği.
/// Key: b3bdb6300731af2986a3f719
final class CurrencyService {
    static let shared = CurrencyService()

    private let cache = LocalCacheService.shared
    private let session: URLSession
    private let endpoint =
        "https://v6.exchangerate-api.com/v6/b3bdb6300731af2986a3f719/latest/USD"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRates() async -> CurrencyRates {
        if let cached = cache.loadIfFresh(
            CurrencyRates.self,
            forKey: CacheKey.currency,
            maxAge: CacheTTL.currency
        ) {
            return cached
        }

        do {
            let fresh = try await requestAPI()
            cache.save(fresh, forKey: CacheKey.currency)
            return fresh
        } catch {
            if let stale = cache.loadStale(CurrencyRates.self, forKey: CacheKey.currency) {
                return stale
            }
            return .fallback
        }
    }

    private func requestAPI() async throws -> CurrencyRates {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard json?["result"] as? String == "success",
              let rates = json?["conversion_rates"] as? [String: Double],
              let tryPerUsd = rates["TRY"],
              let eurPerUsd = rates["EUR"],
              let gbpPerUsd = rates["GBP"] else {
            throw URLError(.cannotParseResponse)
        }

        let xauPerUsd = rates["XAU"] ?? 0
        let xagPerUsd = rates["XAG"] ?? 0
        let goldTry = xauPerUsd > 0 ? tryPerUsd / xauPerUsd : 3200.0
        let silverTry = xagPerUsd > 0 ? tryPerUsd / xagPerUsd : 38.0

        return CurrencyRates(
            usdToTry: tryPerUsd,
            eurToTry: tryPerUsd / eurPerUsd,
            gbpToTry: tryPerUsd / gbpPerUsd,
            goldToTry: goldTry,
            silverToTry: silverTry,
            fetchedAt: Date(),
            isFallback: false
        )
    }
}
