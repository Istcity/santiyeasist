import Foundation

/// GitHub Actions / Remote Config / bundle üzerinden dağıtılan merkezi fiyat feed'i.
struct MaterialPricesFeed: Codable {
  let version: Int
  let updatedAt: Date
  let usdTry: Double?
  let cities: [CityMaterialPrices]
  let extended: [ExtendedMaterialPriceEntry]?

  struct CityMaterialPrices: Codable {
    let cityKey: String
    let cityLabel: String
    let betonC30: MaterialPriceQuote
    let rebar: MaterialPriceQuote
  }

  struct MaterialPriceQuote: Codable {
    let priceTry: Double
    let unit: String
    let source: String
  }

  struct ExtendedMaterialPriceEntry: Codable {
    let id: String
    let priceTry: Double
    let source: String
  }

  func city(matching location: GeoLocation) -> CityMaterialPrices? {
    let key = Self.cityKey(for: location)
    if let exact = cities.first(where: { $0.cityKey == key }) {
      return exact
    }
    return cities.first(where: { $0.cityKey == "canakkale_biga" }) ?? cities.first
  }

  static func cityKey(for location: GeoLocation) -> String {
    let label = location.label.lowercased()
    if label.contains("istanbul") { return "istanbul" }
    if label.contains("ankara") { return "ankara" }
    if label.contains("izmir") { return "izmir" }
    if label.contains("bursa") { return "bursa" }
    return "canakkale_biga"
  }
}

enum MaterialPricesFeedLoader {
  private static let bundledFileName = "material_prices"
  private static let defaultRemoteURL =
    "https://raw.githubusercontent.com/Istcity/santiyeasist/main/data/material_prices.json"

  /// Öncelik: Remote Config JSON → Remote Config URL → bundle → nil
  static func load(session: URLSession = .shared) async -> MaterialPricesFeed? {
    if let fromRC = AppConfigService.shared.materialPricesFeedFromRemoteConfig() {
      return fromRC
    }

    if let urlString = AppConfigService.shared.materialPricesFeedURL,
       let url = URL(string: urlString),
       let feed = await fetchFeed(from: url, session: session) {
      return feed
    }

    return loadBundled()
  }

  static func loadBundled() -> MaterialPricesFeed? {
    guard let url = Bundle.main.url(forResource: bundledFileName, withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
      return nil
    }
    return decodeFeed(data)
  }

  static func fetchFeed(from url: URL, session: URLSession) async -> MaterialPricesFeed? {
    do {
      var request = URLRequest(url: url)
      request.setValue("SantiyeAsist/1.0", forHTTPHeaderField: "User-Agent")
      request.timeoutInterval = 25
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
      return decodeFeed(data)
    } catch {
      return nil
    }
  }

  static func decodeFeed(_ data: Data) -> MaterialPricesFeed? {
    decode(data)
  }

  static func decode(_ data: Data) -> MaterialPricesFeed? {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      let withFraction = ISO8601DateFormatter()
      withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = withFraction.date(from: value) { return date }
      let plain = ISO8601DateFormatter()
      plain.formatOptions = [.withInternetDateTime]
      if let date = plain.date(from: value) { return date }
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
    }
    return try? decoder.decode(MaterialPricesFeed.self, from: data)
  }

  static func defaultRemoteFeedURL() -> String { defaultRemoteURL }
}
