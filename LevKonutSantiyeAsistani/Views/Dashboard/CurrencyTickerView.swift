import SwiftUI

struct CurrencyHeroCard: View {
  let rates: CurrencyRates

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Döviz Kurları")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
          Spacer()
          if rates.isFallback {
            Text("Önbellek")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(AppTheme.gold)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Capsule().fill(AppTheme.gold.opacity(0.15)))
          }
        }

        HStack(spacing: 12) {
          compactRateTile(code: "USD", flag: "🇺🇸", value: rates.usdToTry)
          compactRateTile(code: "EUR", flag: "🇪🇺", value: rates.eurToTry)
        }
      }
    }
  }

  private func compactRateTile(code: String, flag: String, value: Double) -> some View {
    GlassInsetTile {
      HStack(spacing: 8) {
        Text(flag)
          .font(.title3)
        VStack(alignment: .leading, spacing: 2) {
          Text(code)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
          Text(MoneyFormatter.formatAmount(value))
            .font(.headline.bold())
            .foregroundStyle(AppTheme.gold)
        }
        Spacer()
        Text("₺")
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
      }
    }
  }
}
