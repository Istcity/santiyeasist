import Foundation
import CoreLocation

struct GeoLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let label: String
    let isFallback: Bool

    static let gelibolu = GeoLocation(
        latitude: 40.41,
        longitude: 26.67,
        label: "Gelibolu (varsayılan)",
        isFallback: true
    )

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Ayarlardaki şehir adına göre koordinat (bildirim / hava için).
    static func forCityName(_ name: String) -> GeoLocation {
        guard let coords = cityCoordinates[name] else { return .gelibolu }
        return GeoLocation(
            latitude: coords.lat,
            longitude: coords.lon,
            label: name,
            isFallback: false
        )
    }

    private static let lastKnownLocationKey = "last_known_geo_location"

    static func saveLastKnown(_ location: GeoLocation) {
        guard !location.isFallback else { return }
        guard let data = try? JSONEncoder().encode(location) else { return }
        UserDefaults.standard.set(data, forKey: lastKnownLocationKey)
    }

    static func loadLastKnown() -> GeoLocation? {
        guard let data = UserDefaults.standard.data(forKey: lastKnownLocationKey),
              let location = try? JSONDecoder().decode(GeoLocation.self, from: data)
        else { return nil }
        return location
    }

    private static let cityCoordinates: [String: (lat: Double, lon: Double)] = [
        "İstanbul": (41.0082, 28.9784),
        "Ankara": (39.9334, 32.8597),
        "İzmir": (38.4237, 27.1428),
        "Bursa": (40.1885, 29.0610),
        "Antalya": (36.8969, 30.7133),
        "Adana": (37.0000, 35.3213),
        "Konya": (37.8746, 32.4932),
        "Gaziantep": (37.0662, 37.3833),
        "Mersin": (36.8121, 34.6415),
        "Kayseri": (38.7312, 35.4787),
        "Eskişehir": (39.7767, 30.5206),
        "Diyarbakır": (37.9144, 40.2306),
        "Samsun": (41.2867, 36.3300),
        "Trabzon": (41.0027, 39.7168),
        "Çanakkale": (40.1553, 26.4142),
    ]
}
