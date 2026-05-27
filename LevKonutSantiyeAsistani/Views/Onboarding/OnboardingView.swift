import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var settings: AppSettings
  @State private var currentPage = 0

  private let pages: [(icon: String, title: String, subtitle: String, tips: [String])] = [
    (
      "building.2.fill",
      "Şantiye Asist'e\nHoşgeldiniz",
      "İnşaat projelerinizi tek yerden yönetin.",
      ["Tüm şantiye işlemleriniz tek uygulama", "Ücretsiz kullanım, reklam izleyerek premium özellikler"]
    ),
    (
      "turkishlirasign.circle.fill",
      "Maliyet Hesaplama",
      "Canlı beton ve demir fiyatlarıyla anlık maliyet hesabı yapın.",
      ["KDV ve kar marjı ekleyin", "PDF & CSV olarak rapor paylaşın", "Yapı türüne göre özel birim fiyatları"]
    ),
    (
      "cloud.sun.bolt.fill",
      "Canlı Fiyatlar & Hava",
      "Anlık döviz, malzeme fiyatları ve hava durumu takibi.",
      ["USD & EUR döviz kurları", "Demir, beton, çimento fiyatları", "Şehrinize göre hava durumu"]
    ),
    (
      "folder.fill.badge.plus",
      "Proje Yönetimi",
      "Projeleri kolayca oluşturun ve yönetin.",
      ["Projeye uzun basarak düzenleyin", "Sola çekerek silin", "Hakediş, puantaj ve günlük takibi"]
    ),
    (
      "hand.tap.fill",
      "Kullanım İpuçları",
      "Uygulamadan en iyi şekilde faydalanın.",
      ["Aşağı çekerek verileri yenileyin", "Klavyeyi kapatmak için boş alana dokunun", "Ayarlardan şehir ve bildirimleri yönetin"]
    ),
  ]

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient.ignoresSafeArea()

      VStack(spacing: 0) {
        TabView(selection: $currentPage) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            onboardingPage(
              icon: page.icon,
              title: page.title,
              subtitle: page.subtitle,
              tips: page.tips
            )
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)

        VStack(spacing: 16) {
          if currentPage == pages.count - 1 {
            Button {
              settings.hasCompletedOnboarding = true
            } label: {
              Text("Başla")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  LinearGradient(
                    colors: [AppTheme.gold, AppTheme.goldMuted],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .clipShape(Capsule(style: .continuous))
            }
          } else {
            Button {
              withAnimation { currentPage += 1 }
            } label: {
              Text("İleri")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.gold)
                .clipShape(Capsule(style: .continuous))
            }
          }

          if currentPage < pages.count - 1 {
            Button("Atla") {
              settings.hasCompletedOnboarding = true
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.warmGray)
          }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
      }
    }
  }

  private func onboardingPage(icon: String, title: String, subtitle: String, tips: [String]) -> some View {
    VStack(spacing: 20) {
      Spacer()

      SantiyeAsistLogoMark(size: 80)

      Image(systemName: icon)
        .font(.system(size: 56, weight: .light))
        .foregroundStyle(AppTheme.gold)
        .shadow(color: AppTheme.gold.opacity(0.3), radius: 12, y: 6)

      Text(title)
        .font(.title2.bold())
        .multilineTextAlignment(.center)
        .foregroundStyle(AppTheme.navy)

      Text(subtitle)
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 32)

      VStack(alignment: .leading, spacing: 10) {
        ForEach(tips, id: \.self) { tip in
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
              .font(.body)
              .foregroundStyle(AppTheme.gold)
            Text(tip)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textPrimary)
          }
        }
      }
      .padding(.horizontal, 40)
      .padding(.top, 8)

      Spacer()
      Spacer()
    }
  }
}
