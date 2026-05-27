import GoogleMobileAds
import SwiftUI

/// Banner yalnızca 50pt şeridinde dokunma alır; taşan UIKit görünümü ScrollView’u kilitlemez.
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerAdContainerView {
        let container = BannerAdContainerView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        guard let banner = AdManagerService.shared.makeBannerView() else {
            container.isUserInteractionEnabled = false
            return container
        }

        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        let size = GADAdSizeBanner.size
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            banner.widthAnchor.constraint(equalToConstant: size.width),
            banner.heightAnchor.constraint(equalToConstant: size.height),
        ])
        return container
    }

    func updateUIView(_ uiView: BannerAdContainerView, context: Context) {}
}

final class BannerAdContainerView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }
}
