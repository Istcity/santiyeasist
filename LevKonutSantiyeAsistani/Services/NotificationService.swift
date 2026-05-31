import Foundation
import UserNotifications

enum NotificationService {
  static let dailyMorningBriefingID = "daily-morning-briefing"
  private static let briefingHour = 8
  private static let briefingMinute = 30

  static func requestPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
      Task { await refreshDailyMorningBriefing() }
    }
  }

  static func schedulePriceAlert(
    material: String,
    currentPrice: Double,
    targetPrice: Double,
    direction: PriceAlert.AlertDirection
  ) {
    let content = UNMutableNotificationContent()
    content.title = "Fiyat Alarmı - \(material)"

    let dirText = direction == .below ? "altına düştü" : "üstüne çıktı"
    content.body =
      "\(material) fiyatı \(MoneyFormatter.formatTRY(targetPrice)) \(dirText)! Güncel: \(MoneyFormatter.formatTRY(currentPrice))"
    content.sound = .default

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }

  @MainActor
  static func checkPriceAlerts(snapshot: MaterialPriceSnapshot) {
    guard ProjectStore.shared.activeProject != nil else { return }
    _ = snapshot
  }

  // MARK: - Sabah 08:30 günlük özet

  /// Hava + uygulamaya giriş teşviki; her sabah yerel 08:30'da tekrarlar.
  /// - Parameter useCachedLocationOnly: Arka plan yenilemede GPS yerine son bilinen konum.
  @MainActor
  static func cancelDailyMorningBriefing() async {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: [dailyMorningBriefingID]
    )
  }

  @MainActor
  static func refreshDailyMorningBriefing(useCachedLocationOnly: Bool = false) async {
    let center = UNUserNotificationCenter.current()

    guard AppSettings.shared.morningBriefingEnabled else {
      await cancelDailyMorningBriefing()
      return
    }

    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized
      || settings.authorizationStatus == .provisional
    else { return }

    let location = await locationForBriefing(useCachedLocationOnly: useCachedLocationOnly)
    let weather = try? await WeatherService.shared.fetchWeather(for: location)

    center.removePendingNotificationRequests(withIdentifiers: [dailyMorningBriefingID])

    let content = UNMutableNotificationContent()
    content.title = "Günaydın — Şantiye Asist"
    content.body = morningBriefingBody(weather: weather)
    content.sound = .default
    content.categoryIdentifier = "MORNING_BRIEFING"

    var dateComponents = DateComponents()
    dateComponents.hour = briefingHour
    dateComponents.minute = briefingMinute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
      identifier: dailyMorningBriefingID,
      content: content,
      trigger: trigger
    )

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      center.add(request) { _ in continuation.resume() }
    }

    MorningBriefingBackgroundRefresh.scheduleNextRefresh()
  }

  @MainActor
  private static func locationForBriefing(useCachedLocationOnly: Bool) async -> GeoLocation {
    let citySetting = AppSettings.shared.defaultCity
    if citySetting == "Otomatik (GPS)" {
      if useCachedLocationOnly, let cached = GeoLocation.loadLastKnown() {
        return cached
      }
      let live = await LocationService.shared.currentLocation()
      if !live.isFallback {
        GeoLocation.saveLastKnown(live)
      }
      return live
    }
    return GeoLocation.forCityName(citySetting)
  }

  private static func morningBriefingBody(weather: WeatherBundle?) -> String {
    let teaser =
      "Güncel döviz, beton ve demir fiyatları için uygulamayı açın."

    guard let weather else {
      return "Bugünkü hava durumu ve güncel döviz, beton ve demir fiyatları için uygulamayı açın."
    }

    let city = weather.cityName
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let summary = weather.threeDayForecast.first { calendar.isDate($0.date, inSameDayAs: today) }
      ?? weather.threeDayForecast.first

    guard let summary else {
      return "\(city): \(teaser)"
    }

    let temp = Int(summary.maxC.rounded())
    let desc = summary.description.prefix(1).uppercased() + summary.description.dropFirst()
    let rain = Int(summary.precipitationProbability.rounded())

    return "\(city): Bugün ~\(temp)°C, \(desc). Yağış %\(rain). \(teaser)"
  }
}
