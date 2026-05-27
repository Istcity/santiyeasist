import Foundation
import Combine

/// Global interstitial koordinatörü — her N ekran geçişinde tam ekran reklam.
@MainActor
final class AdCoordinator: ObservableObject {
    static let shared = AdCoordinator()

    @Published private(set) var screenTransitionCount = 0
    @Published var interstitialFrequency = 5

    private let adManager = AdManagerService.shared

    func recordScreenTransition() {
        screenTransitionCount += 1
        guard screenTransitionCount >= interstitialFrequency else { return }
        screenTransitionCount = 0
        adManager.showInterstitialIfReady()
    }

    func updateFrequency(from config: AppConfig) {
        interstitialFrequency = max(1, config.interstitialAdFrequency)
    }
}

/// Uygulama geneli durum — reklam geçiş sayacı ve Remote Config frekansı.
@MainActor
final class AppState: ObservableObject {
    @Published var interstitialAdFrequency: Int = 5
    @Published private(set) var navigationTransitionCount: Int = 0

    private let coordinator = AdCoordinator.shared

    func recordScreenTransition() {
        coordinator.recordScreenTransition()
        navigationTransitionCount = coordinator.screenTransitionCount
        interstitialAdFrequency = coordinator.interstitialFrequency
    }

    func updateAdFrequency(from config: AppConfig) {
        coordinator.updateFrequency(from: config)
        interstitialAdFrequency = coordinator.interstitialFrequency
    }
}
