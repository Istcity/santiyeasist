import Foundation
import FirebaseRemoteConfig

/// Firebase Remote Config — Release'te 12 saatte bir fetch.
final class AppConfigService {
    static let shared = AppConfigService()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private(set) var current: AppConfig = .defaults

    private init() {}

    func initialize() async {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 12 * 3600
        #endif
        settings.fetchTimeout = 60
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults([
            "beton_m3_fiyat": NSNumber(value: 3500),
            "demir_ton_fiyat": NSNumber(value: 33000),
            "interstitial_ad_frequency": NSNumber(value: 5),
        ])

        do {
            _ = try await remoteConfig.fetchAndActivate()
        } catch {
            // Varsayılanlar kullanılır
        }

        current = readConfig()
    }

    private func readConfig() -> AppConfig {
        AppConfig(
            betonM3Fiyat: remoteConfig.configValue(forKey: "beton_m3_fiyat").numberValue.doubleValue,
            demirTonFiyat: remoteConfig.configValue(forKey: "demir_ton_fiyat").numberValue.doubleValue,
            interstitialAdFrequency: remoteConfig
                .configValue(forKey: "interstitial_ad_frequency")
                .numberValue
                .intValue
        )
    }

    /// Malzeme fiyatlarını periyodik yeniler (5 dk cache).
    @discardableResult
    func refreshLivePrices() async -> AppConfig {
        do {
            _ = try await remoteConfig.fetch(withExpirationDuration: 300)
            _ = try await remoteConfig.activate()
        } catch {
            // Önbellek / varsayılan değerler kullanılır
        }
        current = readConfig()
        return current
    }
}
