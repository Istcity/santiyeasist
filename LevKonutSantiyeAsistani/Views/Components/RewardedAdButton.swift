import SwiftUI

struct RewardedAdButton<Label: View>: View {
  let feature: PremiumFeature
  let action: () -> Void
  @ViewBuilder let label: () -> Label

  @ObservedObject private var rewardedService = RewardedAdService.shared
  @State private var showingAlert = false

  var body: some View {
    Button {
      if rewardedService.isFeatureUnlocked(feature) {
        action()
      } else {
        showingAlert = true
      }
    } label: {
      HStack(spacing: 6) {
        label()
        if !rewardedService.isFeatureUnlocked(feature) {
          Image(systemName: "play.rectangle.fill")
            .font(.caption)
            .foregroundStyle(AppTheme.gold)
        }
      }
    }
    .alert("Reklam İzle", isPresented: $showingAlert) {
      Button("Reklam İzle") {
        rewardedService.requestFeatureUnlock(feature) { success in
          if success { action() }
        }
      }
      Button("İptal", role: .cancel) {}
    } message: {
      Text("\(feature.displayName) özelliğini kullanmak için kısa bir reklam izleyin. \(feature.sessionDurationMinutes) dakika aktif kalır.")
    }
  }
}
