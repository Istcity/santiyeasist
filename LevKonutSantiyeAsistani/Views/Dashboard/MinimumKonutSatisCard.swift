import SwiftUI

/// Maliyet hesabına dayalı tahmini minimum konut satış bedeli.
struct MinimumKonutSatisCard: View {
  @ObservedObject var costVM: CostCalculatorViewModel
  @State private var konutAreaText = ""

  var body: some View {
    AttentionGlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.title3)
            .foregroundStyle(AppTheme.alertRed)
          VStack(alignment: .leading, spacing: 4) {
            Text("Minimum Konut Satış Bedeli")
              .font(.headline)
              .foregroundStyle(AppTheme.navy)
            Text("Yukarıdaki maliyet hesabına göre tahmini taban fiyat")
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
          }
          Spacer(minLength: 0)
        }

        if let result = costVM.result, let konutArea = parsedKonutArea {
          konutAreaField

          HStack(spacing: 12) {
            metricTile(
              title: "m² birim maliyet",
              value: MoneyFormatter.formatTRY(result.costPerM2Try),
              suffix: "/m²"
            )
            metricTile(
              title: "Konut alanı",
              value: MoneyFormatter.formatAmount(konutArea),
              suffix: "m²"
            )
          }

          VStack(alignment: .leading, spacing: 6) {
            Text("Tahmini minimum satış bedeli")
              .font(.caption.weight(.semibold))
              .foregroundStyle(AppTheme.alertRedMuted)
            Text(MoneyFormatter.formatTRY(minimumSalePrice(result: result, konutArea: konutArea)))
              .font(.title.bold())
              .foregroundStyle(AppTheme.alertRed)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
              .fill(AppTheme.alertRed.opacity(0.08))
          )
          .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
              .stroke(AppTheme.alertRed.opacity(0.25), lineWidth: 1)
          }

          if konutArea > result.totalBuildAreaM2 {
            Text(
              "Girilen alan, toplam inşaat alanından (\(MoneyFormatter.formatAmount(result.totalBuildAreaM2)) m²) büyük; sonuç yine gösterilir."
            )
            .font(.caption2)
            .foregroundStyle(AppTheme.alertRedMuted)
          }
        } else {
          Text("Önce maliyet hesaplamasını yapın; ardından konut m² girerek minimum satış bedelini görebilirsiniz.")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)

          konutAreaField
            .disabled(true)
            .opacity(0.55)
        }
      }
    }
    .onChange(of: costVM.result?.grandTotalTry) { _ in
      if let area = costVM.result?.totalBuildAreaM2, area > 0 {
        konutAreaText = MoneyFormatter.editingString(for: area)
      }
    }
    .onAppear { syncKonutAreaFromCost() }
  }

  private var konutAreaField: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Konut satış alanı (m²)")
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.alertRedMuted)
      TextField("m²", text: $konutAreaText)
        .keyboardType(.decimalPad)
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(AppTheme.navy)
    }
  }

  private var parsedKonutArea: Double? {
    guard let result = costVM.result else { return nil }
    let raw = konutAreaText
      .replacingOccurrences(of: ",", with: ".")
      .trimmingCharacters(in: .whitespaces)
    if let value = Double(raw), value > 0 { return value }
    return result.totalBuildAreaM2 > 0 ? result.totalBuildAreaM2 : nil
  }

  private func minimumSalePrice(result: CostCalculationResult, konutArea: Double) -> Double {
    result.costPerM2Try * konutArea
  }

  private func syncKonutAreaFromCost() {
    guard let area = costVM.result?.totalBuildAreaM2, area > 0 else { return }
    if konutAreaText.isEmpty || Double(konutAreaText.replacingOccurrences(of: ",", with: ".")) == nil {
      konutAreaText = MoneyFormatter.editingString(for: area)
    }
  }

  private func metricTile(title: String, value: String, suffix: String) -> some View {
    GlassInsetTile {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption2)
          .foregroundStyle(AppTheme.textSecondary)
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(value)
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.alertRed)
          Text(suffix)
            .font(.caption2)
            .foregroundStyle(AppTheme.textSecondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
