import SwiftUI

struct HakedisView: View {
  @ObservedObject private var store = ProjectStore.shared
  @ObservedObject private var rewardedService = RewardedAdService.shared
  @State private var showingPDFShare = false

  private var project: SantiyeProject? { store.activeProject }

  private var items: [HakedisItem] { project?.hakedisItems ?? [] }

  private var overallProgress: Double {
    guard !items.isEmpty else { return 0 }
    let totalEstimated = items.reduce(0.0) { $0 + $1.estimatedCostTry }
    guard totalEstimated > 0 else {
      let avgPercent = items.reduce(0.0) { $0 + $1.completionPercent } / Double(items.count)
      return avgPercent / 100
    }
    let totalCompleted = items.reduce(0.0) { $0 + $1.completedCostTry }
    return totalCompleted / totalEstimated
  }

  private var totalEstimated: Double {
    items.reduce(0.0) { $0 + $1.estimatedCostTry }
  }

  private var totalCompleted: Double {
    items.reduce(0.0) { $0 + $1.completedCostTry }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        if let _ = project {
          ScrollView {
            VStack(spacing: 16) {
              overallProgressCard
              hakedisItemsList
              reportButton
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
          }
          .dismissKeyboardOnTap()
        } else {
          noProjectView
        }
      }
      .navigationTitle("Hakediş")
    }
  }

  // MARK: - Overall Progress

  private var overallProgressCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 8) {
          Image(systemName: "chart.bar.doc.horizontal.fill")
            .foregroundStyle(AppTheme.gold)
          Text("Genel İlerleme")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
          Spacer()
          Text("%\(Int(overallProgress * 100))")
            .font(.title3.weight(.bold))
            .foregroundStyle(AppTheme.navy)
        }

        ProgressView(value: overallProgress, total: 1.0)
          .tint(AppTheme.gold)
          .frame(height: 10)

        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Tahmini Toplam")
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
            Text(MoneyFormatter.formatTRY(totalEstimated))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 2) {
            Text("Tamamlanan")
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
            Text(MoneyFormatter.formatTRY(totalCompleted))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.gold)
          }
        }
      }
    }
  }

  // MARK: - Items List

  private var hakedisItemsList: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 8) {
          Image(systemName: "list.bullet.clipboard.fill")
            .foregroundStyle(AppTheme.gold)
          Text("İş Kalemleri")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }

        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          HakedisItemRow(item: item) { updated in
            guard var proj = store.activeProject else { return }
            proj.hakedisItems[index] = updated
            store.activeProject = proj
          }

          if index < items.count - 1 {
            Divider().opacity(0.4)
          }
        }
      }
    }
  }

  // MARK: - Report Button

  private var reportButton: some View {
    RewardedAdButton(feature: .hakedisReport, action: {
      generateAndSharePDF()
    }) {
      HStack {
        Image(systemName: "doc.richtext.fill")
        Text("Rapor Oluştur")
          .font(.headline)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
    }
    .buttonStyle(.borderedProminent)
    .tint(AppTheme.gold)
  }

  private var noProjectView: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.bar.doc.horizontal")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))
      Text("Aktif proje yok")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("Hakediş takibi için bir proje seçin")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }

  private func generateAndSharePDF() {
    guard let project else { return }

    let pdfData = HakedisPDFService.generate(
      projectName: project.name,
      items: project.hakedisItems,
      overallProgress: overallProgress,
      totalEstimated: totalEstimated,
      totalCompleted: totalCompleted
    )

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("Hakedis_\(project.name).pdf")
    try? pdfData.write(to: url)

    let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let root = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController {
      root.present(activity, animated: true)
    }
  }
}

// MARK: - Row View

private struct HakedisItemRow: View {
  let item: HakedisItem
  let onUpdate: (HakedisItem) -> Void

  @State private var completion: Double
  @State private var costText: String

  init(item: HakedisItem, onUpdate: @escaping (HakedisItem) -> Void) {
    self.item = item
    self.onUpdate = onUpdate
    _completion = State(initialValue: item.completionPercent)
    _costText = State(initialValue: item.estimatedCostTry > 0
      ? String(format: "%.0f", item.estimatedCostTry) : "")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(item.name)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(AppTheme.textPrimary)

      HStack {
        Text("Tahmini Maliyet")
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
        Spacer()
        TextField("₺ Tutar", text: $costText)
          .textFieldStyle(.plain)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.trailing)
          .frame(width: 120)
          .padding(8)
          .background(Color.white.opacity(0.55))
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
          .onChange(of: costText) { _ in commitChange() }
      }

      HStack(spacing: 8) {
        Text("%\(Int(completion))")
          .font(.caption.weight(.semibold).monospacedDigit())
          .foregroundStyle(AppTheme.navy)
          .frame(width: 36)

        Slider(value: $completion, in: 0...100, step: 5)
          .tint(AppTheme.gold)
          .onChange(of: completion) { _ in commitChange() }
      }

      let cost = (Double(costText) ?? 0) * completion / 100
      if cost > 0 {
        Text("Tamamlanan: \(MoneyFormatter.formatTRY(cost))")
          .font(.caption)
          .foregroundStyle(AppTheme.gold)
      }
    }
    .padding(.vertical, 4)
  }

  private func commitChange() {
    var updated = item
    updated.completionPercent = completion
    updated.estimatedCostTry = Double(costText) ?? 0
    onUpdate(updated)
  }
}

// MARK: - PDF Service

enum HakedisPDFService {
  static func generate(
    projectName: String,
    items: [HakedisItem],
    overallProgress: Double,
    totalEstimated: Double,
    totalCompleted: Double
  ) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    return renderer.pdfData { context in
      context.beginPage()
      let titleAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 20),
        .foregroundColor: UIColor(red: 0.04, green: 0.12, blue: 0.23, alpha: 1),
      ]
      let bodyAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.darkGray,
      ]
      let boldAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 12),
        .foregroundColor: UIColor(red: 0.04, green: 0.12, blue: 0.23, alpha: 1),
      ]

      var y: CGFloat = 40
      let marginX: CGFloat = 40

      ("Hakediş Raporu - \(projectName)" as NSString)
        .draw(at: CGPoint(x: marginX, y: y), withAttributes: titleAttr)
      y += 36

      let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
      ("Tarih: \(dateStr)" as NSString)
        .draw(at: CGPoint(x: marginX, y: y), withAttributes: bodyAttr)
      y += 28

      ("Genel İlerleme: %\(Int(overallProgress * 100))" as NSString)
        .draw(at: CGPoint(x: marginX, y: y), withAttributes: boldAttr)
      y += 24

      for item in items {
        if y > 780 {
          context.beginPage()
          y = 40
        }
        let line = "\(item.name): %\(Int(item.completionPercent)) — Tahmini: \(MoneyFormatter.formatTRY(item.estimatedCostTry)) — Tamamlanan: \(MoneyFormatter.formatTRY(item.completedCostTry))"
        (line as NSString).draw(
          in: CGRect(x: marginX, y: y, width: 515, height: 40),
          withAttributes: bodyAttr
        )
        y += 22
      }

      y += 16
      let total = "Toplam Tahmini: \(MoneyFormatter.formatTRY(totalEstimated))  |  Tamamlanan: \(MoneyFormatter.formatTRY(totalCompleted))"
      (total as NSString).draw(at: CGPoint(x: marginX, y: y), withAttributes: boldAttr)
    }
  }
}
