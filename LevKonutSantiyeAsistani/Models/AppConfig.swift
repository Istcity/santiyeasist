import Foundation

struct AppConfig: Codable {
    var betonM3Fiyat: Double
    var demirTonFiyat: Double
    var interstitialAdFrequency: Int

    static let defaults = AppConfig(
        betonM3Fiyat: 3500,
        demirTonFiyat: 33000,
        interstitialAdFrequency: 5
    )
}
