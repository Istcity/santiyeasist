import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdService: NSObject, ObservableObject {
  static let shared = RewardedAdService()

  private let rewardedTestID = "ca-app-pub-3940256099942544/1712485313"
  private var rewardedAd: GADRewardedAd?
  private var isLoading = false
  private var pendingCompletion: ((Bool) -> Void)?

  @Published private(set) var unlockedFeatures: [PremiumFeature: Date] = [:]

  private override init() {
    super.init()
    preload()
  }

  var isAdLoaded: Bool { rewardedAd != nil }

  func isFeatureUnlocked(_ feature: PremiumFeature) -> Bool {
    guard let unlockDate = unlockedFeatures[feature] else { return false }
    return Date().timeIntervalSince(unlockDate) < Double(feature.sessionDurationMinutes) * 60
  }

  func remainingTime(for feature: PremiumFeature) -> TimeInterval? {
    guard let unlockDate = unlockedFeatures[feature] else { return nil }
    let elapsed = Date().timeIntervalSince(unlockDate)
    let total = Double(feature.sessionDurationMinutes) * 60
    let remaining = total - elapsed
    return remaining > 0 ? remaining : nil
  }

  func requestFeatureUnlock(_ feature: PremiumFeature, completion: @escaping (Bool) -> Void) {
    guard AdsBootstrap.isReady else {
      unlockFeature(feature)
      completion(true)
      return
    }
    guard let ad = rewardedAd, let root = rootViewController else {
      unlockFeature(feature)
      completion(true)
      return
    }

    pendingCompletion = { [weak self] success in
      if success { self?.unlockFeature(feature) }
      completion(success)
    }

    ad.present(fromRootViewController: root) { [weak self] in
      Task { @MainActor in
        self?.pendingCompletion?(true)
        self?.pendingCompletion = nil
        self?.rewardedAd = nil
        self?.preload()
      }
    }
  }

  private func unlockFeature(_ feature: PremiumFeature) {
    unlockedFeatures[feature] = Date()
  }

  func preload() {
    guard AdsBootstrap.isReady, !isLoading, rewardedAd == nil else { return }
    isLoading = true

    GADRewardedAd.load(withAdUnitID: rewardedTestID, request: GADRequest()) { [weak self] ad, _ in
      Task { @MainActor in
        self?.isLoading = false
        self?.rewardedAd = ad
      }
    }
  }

  private var rootViewController: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  }
}
