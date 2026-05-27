import Foundation

/// OpenWeatherMap — UserDefaults önbellek, 60 dakikada en fazla 1 HTTP isteği.
/// API Key: dfeb9d445f1cbe9f14a30c68bf079564
final class WeatherService {
    static let shared = WeatherService()

    private let cache = LocalCacheService.shared
    private let session: URLSession
    private let apiKey = "dfeb9d445f1cbe9f14a30c68bf079564"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(for location: GeoLocation) async throws -> WeatherBundle {
        let cacheKey = "\(CacheKey.weather)_\(location.latitude)_\(location.longitude)"

        if let cached = cache.loadIfFresh(
            WeatherBundle.self,
            forKey: cacheKey,
            maxAge: CacheTTL.weather
        ) {
            return cached
        }

        do {
            let fresh = try await requestAPI(location: location)
            cache.save(fresh, forKey: cacheKey)
            return fresh
        } catch {
            if let stale = cache.loadStale(WeatherBundle.self, forKey: cacheKey) {
                return stale
            }
            throw error
        }
    }

    private func requestAPI(location: GeoLocation) async throws -> WeatherBundle {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "tr"),
            URLQueryItem(name: "cnt", value: "40"),
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try parseForecast(data: data, location: location)
    }

    private func parseForecast(data: Data, location: GeoLocation) throws -> WeatherBundle {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let city = (json?["city"] as? [String: Any])?["name"] as? String ?? location.label
        let list = json?["list"] as? [[String: Any]] ?? []

        let items: [WeatherForecastItem] = list.compactMap { entry in
            guard let dt = entry["dt"] as? TimeInterval,
                  let main = entry["main"] as? [String: Any],
                  let temp = main["temp"] as? Double,
                  let tempMin = main["temp_min"] as? Double,
                  let tempMax = main["temp_max"] as? Double,
                  let humidity = main["humidity"] as? Int,
                  let weatherArr = entry["weather"] as? [[String: Any]],
                  let w0 = weatherArr.first,
                  let desc = w0["description"] as? String else { return nil }

            let wind = entry["wind"] as? [String: Any]
            let windMs = wind?["speed"] as? Double ?? 0
            let pop = (entry["pop"] as? Double ?? 0) * 100

            return WeatherForecastItem(
                date: Date(timeIntervalSince1970: dt),
                tempC: temp,
                tempMinC: tempMin,
                tempMaxC: tempMax,
                humidity: humidity,
                windSpeedKmh: windMs * 3.6,
                precipitationProbability: pop,
                description: desc
            )
        }

        return WeatherBundle(
            location: location,
            cityName: city,
            items: items,
            fetchedAt: Date()
        )
    }
}
