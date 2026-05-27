import Foundation
import GoogleMobileAds

/// AdMob SDK başlamadan banner/interstitial yüklenmesini engeller.
@MainActor
enum AdsBootstrap {
    private(set) static var isReady = false

    static func configure() async {
        guard !isReady else { return }

        await withCheckedContinuation { continuation in
            GADMobileAds.sharedInstance().start { _ in
                Task { @MainActor in
                    isReady = true
                    continuation.resume()
                }
            }
        }
    }
}
