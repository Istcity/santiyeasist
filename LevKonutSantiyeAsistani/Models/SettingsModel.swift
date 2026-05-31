import Foundation
import UIKit

@MainActor
final class AppSettings: ObservableObject {
  static let shared = AppSettings()

  @Published var defaultCity: String {
    didSet { UserDefaults.standard.set(defaultCity, forKey: "settings_default_city") }
  }
  @Published var hapticEnabled: Bool {
    didSet { UserDefaults.standard.set(hapticEnabled, forKey: "settings_haptic") }
  }
  @Published var hasCompletedOnboarding: Bool {
    didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "settings_onboarding_done") }
  }
  @Published var priceAlerts: [PriceAlert] {
    didSet { savePriceAlerts() }
  }
  @Published var morningBriefingEnabled: Bool {
    didSet {
      UserDefaults.standard.set(morningBriefingEnabled, forKey: "settings_morning_briefing")
      Task { @MainActor in
        if morningBriefingEnabled {
          NotificationService.requestPermission()
        } else {
          await NotificationService.cancelDailyMorningBriefing()
          MorningBriefingBackgroundRefresh.cancelScheduledRefresh()
        }
      }
    }
  }

  static var versionLabel: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "Sürüm \(version) (\(build))"
  }

  static let availableCities = [
    "Otomatik (GPS)", "İstanbul", "Ankara", "İzmir", "Bursa", "Antalya",
    "Adana", "Konya", "Gaziantep", "Mersin", "Kayseri", "Eskişehir",
    "Diyarbakır", "Samsun", "Trabzon", "Çanakkale",
  ]

  private init() {
    self.defaultCity = UserDefaults.standard.string(forKey: "settings_default_city") ?? "Otomatik (GPS)"
    self.hapticEnabled = UserDefaults.standard.object(forKey: "settings_haptic") as? Bool ?? true
    self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "settings_onboarding_done")
    self.morningBriefingEnabled =
      UserDefaults.standard.object(forKey: "settings_morning_briefing") as? Bool ?? true

    if let data = UserDefaults.standard.data(forKey: "settings_price_alerts"),
       let alerts = try? JSONDecoder().decode([PriceAlert].self, from: data) {
      self.priceAlerts = alerts
    } else {
      self.priceAlerts = []
    }
  }

  func addPriceAlert(_ alert: PriceAlert) {
    priceAlerts.append(alert)
  }

  func removePriceAlert(id: UUID) {
    priceAlerts.removeAll { $0.id == id }
  }

  private func savePriceAlerts() {
    guard let data = try? JSONEncoder().encode(priceAlerts) else { return }
    UserDefaults.standard.set(data, forKey: "settings_price_alerts")
  }

  func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    guard hapticEnabled else { return }
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }
}
