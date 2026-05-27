import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
  @Published private(set) var weather: WeatherBundle?
  @Published private(set) var advices: [ConstructionAdvice] = []
  @Published private(set) var currency: CurrencyRates?
  @Published private(set) var config: AppConfig = .defaults
  @Published private(set) var materialSnapshot = MaterialPriceSnapshot(
    betonM3Fiyat: AppConfig.defaults.betonM3Fiyat,
    demirTonFiyat: AppConfig.defaults.demirTonFiyat,
    updatedAt: Date(),
    demirSource: "—",
    betonSource: "—",
    cityLabel: nil
  )
  @Published private(set) var currentLocation: GeoLocation = .gelibolu
  @Published private(set) var isLoading = false
  @Published private(set) var isRefreshingPrices = false
  @Published var errorMessage: String?

  private let locationService = LocationService.shared
  private let weatherService = WeatherService.shared
  private let currencyService = CurrencyService.shared
  private let configService = AppConfigService.shared
  private let materialService = MaterialPriceService.shared
  private var liveRefreshTask: Task<Void, Never>?

  func load(appState: AppState) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    await configService.initialize()
    config = configService.current
    appState.updateAdFrequency(from: config)

    let location = await locationService.currentLocation()
    currentLocation = location
    let rates = await currencyService.fetchRates()
    currency = rates

    materialSnapshot = await materialService.fetchLivePrices(
      currency: rates,
      location: location,
      configFallback: config
    )

    do {
      let weatherBundle = try await weatherService.fetchWeather(for: location)
      weather = weatherBundle
      advices = WeatherAnalyzer.analyze(weatherBundle)
      await NotificationService.refreshDailyMorningBriefing()
    } catch {
      errorMessage = "Hava: \(error.localizedDescription)"
      await NotificationService.refreshDailyMorningBriefing()
    }
  }

  func startLivePriceUpdates(appState: AppState) {
    liveRefreshTask?.cancel()
    liveRefreshTask = Task {
      while !Task.isCancelled {
        await refreshMaterialPrices(appState: appState)
        try? await Task.sleep(nanoseconds: 90_000_000_000)
      }
    }
  }

  func stopLivePriceUpdates() {
    liveRefreshTask?.cancel()
    liveRefreshTask = nil
  }

  func refreshMaterialPrices(appState: AppState) async {
    isRefreshingPrices = true
    defer { isRefreshingPrices = false }

    let rates: CurrencyRates
    if let currency {
      rates = currency
    } else {
      rates = await currencyService.fetchRates()
      currency = rates
    }

    materialSnapshot = await materialService.fetchLivePrices(
      currency: rates,
      location: currentLocation,
      configFallback: config,
      forceRefresh: true
    )
    appState.updateAdFrequency(from: config)
  }
}
