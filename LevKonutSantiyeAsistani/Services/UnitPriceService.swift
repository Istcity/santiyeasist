import Foundation

/// Asset JSON + Remote Config (beton/demir) birleşimi.
enum UnitPriceService {
    /// Maliyet hesabında kullanılan birim fiyat anahtarları (sıralı).
    static let costLinePriceIDs = [
        "excavation", "concrete_c30", "rebar", "wall",
        "electrical", "mechanical", "finishing", "permits",
    ]

    static func loadPrices(snapshot: MaterialPriceSnapshot) -> [String: UnitPrice] {
        var map = loadBundled()
        map["concrete_c30"] = UnitPrice(
            id: "concrete_c30",
            name: "Hazır Beton (C30)",
            unit: "m3",
            priceTry: snapshot.betonM3Fiyat
        )
        map["rebar"] = UnitPrice(
            id: "rebar",
            name: "İnşaat Demiri",
            unit: "Ton",
            priceTry: snapshot.demirTonFiyat
        )
        return map
    }

    static func loadPrices(config: AppConfig) -> [String: UnitPrice] {
        let snapshot = MaterialPriceSnapshot(
            betonM3Fiyat: config.betonM3Fiyat,
            demirTonFiyat: config.demirTonFiyat,
            updatedAt: Date(),
            demirSource: "Firebase",
            betonSource: "Firebase",
            cityLabel: nil
        )
        return loadPrices(snapshot: snapshot)
    }

    private static func loadBundled() -> [String: UnitPrice] {
        guard let url = Bundle.main.url(
            forResource: "default_unit_prices",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let list = try? JSONDecoder().decode([UnitPrice].self, from: data) else {
            return fallbackPrices()
        }
        return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    private static func fallbackPrices() -> [String: UnitPrice] {
        let defaults: [(String, String, String, Double)] = [
            ("concrete_c30", "Hazır Beton (C30)", "m3", 3500),
            ("rebar", "İnşaat Demiri", "Ton", 33000),
            ("wall", "Duvar", "m2", 350),
            ("excavation", "Hafriyat", "m3", 180),
            ("electrical", "Elektrik", "m2", 1500),
            ("mechanical", "Mekanik", "m2", 1800),
            ("finishing", "İnce İşler", "m2", 4500),
            ("permits", "Ruhsat", "m2", 1200),
        ]
        return Dictionary(uniqueKeysWithValues: defaults.map { id, name, unit, price in
            (id, UnitPrice(id: id, name: name, unit: unit, priceTry: price))
        })
    }
}

// MARK: - Canlı malzeme fiyatları

/// Merkezi feed (GitHub Actions) → uygulama; yedek: bundle / endeks.
final class MaterialPriceService {
    static let shared = MaterialPriceService()

    private let cache = LocalCacheService.shared
    private let session: URLSession

    private let referenceUsdTry = 35.0
    private let referenceBetonM3 = 3720.74

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLivePrices(
        currency: CurrencyRates,
        location: GeoLocation,
        configFallback: AppConfig,
        forceRefresh: Bool = false
    ) async -> MaterialPriceSnapshot {
        let cacheKey = "\(CacheKey.materialPrices)_\(location.label)"

        if forceRefresh {
            cache.remove(forKey: cacheKey)
            cache.remove(forKey: CacheKey.materialPricesFeed)
        }

        if !forceRefresh,
           let cached = cache.loadIfFresh(
            MaterialPriceSnapshot.self,
            forKey: cacheKey,
            maxAge: CacheTTL.materialPrices
        ),
           !isLegacySnapshot(cached) {
            return await MainActor.run {
                MaterialPriceOverridesStore.shared.apply(to: cached)
            }
        }

        let snapshot: MaterialPriceSnapshot
        if let feed = await loadFeed(forceRefresh: forceRefresh),
           let city = feed.city(matching: location) {
            snapshot = MaterialPriceSnapshot(
                betonM3Fiyat: city.betonC30.priceTry,
                demirTonFiyat: city.rebar.priceTry,
                updatedAt: feed.updatedAt,
                demirSource: city.rebar.source,
                betonSource: city.betonC30.source,
                cityLabel: city.cityLabel
            )
            await MainActor.run {
                ExtendedMaterialStore.shared.applyFeedPrices(feed.extended)
            }
        } else {
            snapshot = await legacyFallbackSnapshot(
                currency: currency,
                location: location,
                configFallback: configFallback
            )
        }

        let withOverrides = await MainActor.run {
            MaterialPriceOverridesStore.shared.apply(to: snapshot)
        }
        cache.save(withOverrides, forKey: cacheKey)
        return withOverrides
    }

    private func isLegacySnapshot(_ snapshot: MaterialPriceSnapshot) -> Bool {
        let legacyMarkers = ["endeks", "firebase", "—"]
        let beton = snapshot.betonSource.lowercased()
        let demir = snapshot.demirSource.lowercased()
        return legacyMarkers.contains(where: { beton.contains($0) || demir.contains($0) })
    }

    private func loadFeed(forceRefresh: Bool) async -> MaterialPricesFeed? {
        if !forceRefresh,
           let cached = cache.loadIfFresh(
            MaterialPricesFeed.self,
            forKey: CacheKey.materialPricesFeed,
            maxAge: CacheTTL.materialPricesFeed
           ) {
            return cached
        }

        if let stale = cache.loadStale(MaterialPricesFeed.self, forKey: CacheKey.materialPricesFeed),
           !forceRefresh {
            Task {
                if let fresh = await MaterialPricesFeedLoader.load(session: session, forceRefresh: true) {
                    cache.save(fresh, forKey: CacheKey.materialPricesFeed)
                }
            }
            return stale
        }

        guard let feed = await MaterialPricesFeedLoader.load(session: session, forceRefresh: forceRefresh) else {
            return cache.loadStale(MaterialPricesFeed.self, forKey: CacheKey.materialPricesFeed)
        }
        cache.save(feed, forKey: CacheKey.materialPricesFeed)
        return feed
    }

    private func legacyFallbackSnapshot(
        currency: CurrencyRates,
        location: GeoLocation,
        configFallback: AppConfig
    ) async -> MaterialPriceSnapshot {
        let demir = await fetchDemirFromWeb(preferredCity: preferredCity(for: location))
        let beton = indexedBetonPrice(usdTry: currency.usdToTry, configFallback: configFallback)

        if let demir {
            return MaterialPriceSnapshot(
                betonM3Fiyat: beton.price,
                demirTonFiyat: demir.pricePerTon,
                updatedAt: Date(),
                demirSource: "insaatdemiri.net",
                betonSource: beton.source,
                cityLabel: demir.city
            )
        }

        return MaterialPriceSnapshot(
            betonM3Fiyat: beton.price,
            demirTonFiyat: indexedDemirPrice(usdTry: currency.usdToTry, configFallback: configFallback),
            updatedAt: Date(),
            demirSource: "USD endeksi",
            betonSource: beton.source,
            cityLabel: location.label
        )
    }

    private struct DemirQuote {
        let city: String
        let pricePerTon: Double
    }

    private struct BetonQuote {
        let price: Double
        let source: String
    }

    private func preferredCity(for location: GeoLocation) -> String {
        let label = location.label.lowercased()
        if label.contains("istanbul") { return "İstanbul (Avrupa)" }
        if label.contains("ankara") { return "Ankara" }
        if label.contains("izmir") { return "İzmir" }
        if label.contains("bursa") { return "Bursa" }
        return "Çanakkale Biga"
    }

    private func fetchDemirFromWeb(preferredCity: String) async -> DemirQuote? {
        guard let url = URL(string: "https://www.insaatdemiri.net/") else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else { return nil }

            let rows = parseDemirRows(html: html)
            if let match = rows.first(where: { $0.city.caseInsensitiveCompare(preferredCity) == .orderedSame }) {
                return match
            }
            if let fallback = rows.first(where: { $0.city.contains("Çanakkale") }) {
                return fallback
            }
            return rows.first
        } catch {
            return nil
        }
    }

    private func parseDemirRows(html: String) -> [DemirQuote] {
        let pattern = #"<td class="column-1"><a[^>]*>([^<]+)</a></td><td class="column-2">[^<]+</td><td class="column-3">([0-9\.]+)\s*₺"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let cityRange = Range(match.range(at: 1), in: html),
                  let priceRange = Range(match.range(at: 2), in: html),
                  let price = Double(html[priceRange].replacingOccurrences(of: ".", with: "")) else {
                return nil
            }
            return DemirQuote(city: String(html[cityRange]), pricePerTon: price)
        }
    }

    private func indexedBetonPrice(usdTry: Double, configFallback: AppConfig) -> BetonQuote {
        let factor = usdTry / referenceUsdTry
        let indexed = referenceBetonM3 * (0.55 + 0.45 * factor)
        let blended = (indexed * 0.65) + (configFallback.betonM3Fiyat * 0.35)
        return BetonQuote(price: blended, source: "İLBANK + USD endeksi")
    }

    private func indexedDemirPrice(usdTry: Double, configFallback: AppConfig) -> Double {
        configFallback.demirTonFiyat * (usdTry / referenceUsdTry)
    }
}
