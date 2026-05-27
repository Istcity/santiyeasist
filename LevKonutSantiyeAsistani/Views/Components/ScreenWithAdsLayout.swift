import SwiftUI

/// İçerik sarmalayıcı — reklamlar kartlar arasında gösterilir.
struct ScreenWithAdsLayout<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

struct InlineAdBanner: View {
    var body: some View {
        BannerAdView()
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.35))
            )
    }
}
