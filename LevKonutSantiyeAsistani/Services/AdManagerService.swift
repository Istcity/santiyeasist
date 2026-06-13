import Foundation
import GoogleMobileAds
import UIKit

/*
 Info.plist:
 GADApplicationIdentifier → ca-app-pub-8420759480841389~1653740471
 NSLocationWhenInUseUsageDescription → Konum açıklaması
 */

/// AdMob banner + interstitial yönetimi (AdManager).
@MainActor
final class AdManagerService: NSObject {
    static let shared = AdManagerService()

    #if DEBUG
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private let bannerAdUnitID = "ca-app-pub-8420759480841389/3740847767"
    private let interstitialAdUnitID = "ca-app-pub-8420759480841389/2427766096"
    #endif

    private var interstitial: GADInterstitialAd?
    private var isLoadingInterstitial = false

    private override init() {
        super.init()
    }

    func preloadInterstitial() {
        guard AdsBootstrap.isReady else { return }
        guard !isLoadingInterstitial, interstitial == nil else { return }
        isLoadingInterstitial = true

        GADInterstitialAd.load(
            withAdUnitID: interstitialAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, _ in
            Task { @MainActor in
                self?.isLoadingInterstitial = false
                guard let self, let ad else { return }
                self.interstitial = ad
                ad.fullScreenContentDelegate = self
            }
        }
    }

    func showInterstitialIfReady() {
        guard AdsBootstrap.isReady else { return }
        guard let interstitial else {
            preloadInterstitial()
            return
        }
        guard let root = rootViewController else { return }

        interstitial.present(fromRootViewController: root)
        self.interstitial = nil
    }

    func makeBannerView() -> GADBannerView? {
        guard AdsBootstrap.isReady else { return nil }

        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = bannerAdUnitID
        banner.rootViewController = rootViewController
        banner.load(GADRequest())
        return banner
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

extension AdManagerService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            preloadInterstitial()
        }
    }

    nonisolated func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            preloadInterstitial()
        }
    }
}
