import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = DashboardViewModel()
  @StateObject private var costVM = CostCalculatorViewModel()
  @StateObject private var inspectionVM = InspectionViewModel()
  @ObservedObject private var manualCostStore = ManualCostStore.shared

  var body: some View {
    GeometryReader { outer in
      ZStack(alignment: .top) {
        AppTheme.backgroundGradient.ignoresSafeArea()
        backgroundOrbs

        VStack(spacing: 0) {
          DashboardFixedHeader()
            .padding(.top, outer.safeAreaInsets.top)

          ScrollView {
            VStack(alignment: .leading, spacing: 18) {
              DateTimeCard()

              if let rates = viewModel.currency {
                CurrencyHeroCard(rates: rates)
              } else if viewModel.isLoading {
                ProgressView().tint(AppTheme.gold)
              }

              InlineAdBanner()

              LiveMaterialPricesCard(
                snapshot: viewModel.materialSnapshot,
                isRefreshing: viewModel.isRefreshingPrices
              )

              InlineAdBanner()

              ExtendedMaterialsCard()

              InlineAdBanner()

              weatherSection

              InlineAdBanner()

              DashboardCostSection(
                costVM: costVM,
                manualCostStore: manualCostStore
              )

              InlineAdBanner()

              DashboardInspectionSection(viewModel: inspectionVM)

              InlineAdBanner()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
          }
          .dismissKeyboardOnTap()
          .refreshable {
            await viewModel.load(appState: appState)
            costVM.applyMaterialSnapshot(viewModel.materialSnapshot)
          }
        }
      }
    }
    .task {
      inspectionVM.load()
      await viewModel.load(appState: appState)
      costVM.applyMaterialSnapshot(viewModel.materialSnapshot)
      viewModel.startLivePriceUpdates(appState: appState)
    }
    .onChange(of: viewModel.materialSnapshot) { snapshot in
      costVM.applyMaterialSnapshot(snapshot)
    }
    .onDisappear {
      viewModel.stopLivePriceUpdates()
    }
  }

  private var backgroundOrbs: some View {
    ZStack {
      Circle()
        .fill(AppTheme.gold.opacity(0.18))
        .frame(width: 220, height: 220)
        .blur(radius: 60)
        .offset(x: -120, y: -80)
      Circle()
        .fill(AppTheme.navy.opacity(0.12))
        .frame(width: 260, height: 260)
        .blur(radius: 70)
        .offset(x: 140, y: 200)
    }
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private var weatherSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        if let w = viewModel.weather {
          HStack {
            Image(systemName: "location.fill")
              .foregroundStyle(AppTheme.gold)
            Text("\(w.cityName)")
              .font(.headline)
              .foregroundStyle(AppTheme.navy)
            Spacer()
            Text(viewModel.currentLocation.isFallback ? "Varsayılan konum" : "GPS")
              .font(.caption2)
              .foregroundStyle(AppTheme.warmGray)
          }

          Text("3 Günlük Hava Tahmini")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.warmGray)

          ForEach(w.threeDayForecast) { day in
            HStack {
              Text(day.weekdayLabel)
                .font(.subheadline.weight(.medium))
                .frame(width: 90, alignment: .leading)
              Text(day.description.capitalized)
                .font(.caption)
                .foregroundStyle(AppTheme.warmGray)
                .lineLimit(1)
              Spacer()
              Text("\(Int(day.minC))° / \(Int(day.maxC))°")
                .font(.subheadline.bold())
              Text("Yağış %\(Int(day.precipitationProbability))")
                .font(.caption2)
                .foregroundStyle(AppTheme.warmGray)
            }
            .foregroundStyle(AppTheme.navy)
          }

          if let advice = viewModel.advices.first {
            adviceBanner(advice)
          }
        } else if viewModel.isLoading {
          ProgressView("Hava alınıyor…")
        } else if let err = viewModel.errorMessage {
          Text(err).foregroundStyle(.red)
        }
      }
    }
  }

  private func adviceBanner(_ advice: ConstructionAdvice) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(severityColor(advice.severity))
      VStack(alignment: .leading, spacing: 4) {
        Text(advice.title).font(.subheadline.bold())
        Text(advice.message).font(.caption)
      }
    }
    .padding(12)
    .background(severityColor(advice.severity).opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private func severityColor(_ s: ConstructionAdvice.AdviceSeverity) -> Color {
    switch s {
    case .critical: return .red
    case .warning: return .orange
    case .info: return .blue
    }
  }
}

// MARK: - Gömülü maliyet kartı

private struct DashboardCostSection: View {
  @ObservedObject var costVM: CostCalculatorViewModel
  @ObservedObject var manualCostStore: ManualCostStore

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 8) {
          Text("Maliyet Hesaplama")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
          StackedBricksIcon()
          Spacer(minLength: 0)
        }

        Text(
          "Beton \(MoneyFormatter.formatTRYPerUnit(costVM.materialSnapshot.betonM3Fiyat, unit: "m³")) • "
            + "Demir \(MoneyFormatter.formatTRYPerUnit(costVM.materialSnapshot.demirTonFiyat, unit: "ton"))"
        )
        .font(.caption)
        .foregroundStyle(AppTheme.warmGray)

        field("Proje adı", text: $costVM.projectName, keyboard: .default)
        
        VStack(alignment: .leading, spacing: 4) {
          Text("Bina tipi").font(.caption).foregroundStyle(AppTheme.warmGray)
          Picker("Bina tipi", selection: $costVM.buildingType) {
            ForEach(BuildingType.allCases) { type in
              Text(type.rawValue).tag(type)
            }
          }
          .pickerStyle(.segmented)
        }
        
        field("Arsa alanı (m²)", text: $costVM.landAreaText, keyboard: .decimalPad)
        field("Taban oturumu (m²)", text: $costVM.footprintText, keyboard: .decimalPad)
        field("Kat sayısı", text: $costVM.floorCountText, keyboard: .numberPad)
        
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 2) {
            Text("KDV %\(Int(costVM.kdvPercent))").font(.caption).foregroundStyle(AppTheme.warmGray)
            Slider(value: $costVM.kdvPercent, in: 0...30, step: 1)
              .tint(AppTheme.gold)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text("Kar %\(Int(costVM.karMarjiPercent))").font(.caption).foregroundStyle(AppTheme.warmGray)
            Slider(value: $costVM.karMarjiPercent, in: 0...50, step: 1)
              .tint(AppTheme.gold)
          }
        }

        if let error = costVM.validationError {
          Text(error).font(.caption).foregroundStyle(.red)
        }

        HStack(spacing: 10) {
          Button {
            costVM.calculate(manualItems: manualCostStore.items)
          } label: {
            HStack {
              if costVM.isCalculating { ProgressView().tint(.white) }
              Text(costVM.isCalculating ? "Hesaplanıyor…" : "Hesapla")
                .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
          }
          .buttonStyle(.borderedProminent)
          .tint(AppTheme.gold)
          .disabled(costVM.isCalculating)

          Button {
            costVM.resetCost(manualCostStore: manualCostStore)
          } label: {
            Text("Sıfırla")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
          }
          .buttonStyle(.bordered)
          .tint(AppTheme.navy)
        }

        if let result = costVM.result {
          Divider().overlay(AppTheme.warmGray.opacity(0.25))
          Text(MoneyFormatter.formatTRY(result.grandTotalTry))
            .font(.title2.bold())
            .foregroundStyle(AppTheme.gold)

          ForEach(result.lineItems) { item in
            HStack {
              Text(item.label).font(.caption)
              Spacer()
              Text(MoneyFormatter.formatTRY(item.totalTry)).font(.caption.bold())
            }
          }

          ForEach(result.manualItems.filter { $0.amountTry > 0 }) { item in
            HStack {
              Text(item.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Ek kalem" : item.title)
                .font(.caption)
              Spacer()
              Text(MoneyFormatter.formatTRY(item.amountTry)).font(.caption.bold())
            }
          }

          if result.kdvAmount > 0 {
            HStack {
              Text("KDV").font(.caption)
              Spacer()
              Text(MoneyFormatter.formatTRY(result.kdvAmount)).font(.caption.bold())
            }
          }
          if result.karMarjiAmount > 0 {
            HStack {
              Text("Kar Marjı").font(.caption)
              Spacer()
              Text(MoneyFormatter.formatTRY(result.karMarjiAmount)).font(.caption.bold())
            }
          }

          HStack(spacing: 10) {
            Button { costVM.sharePDF() } label: {
              Label("PDF", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.gold)
            
            Button { costVM.shareCSV() } label: {
              Label("CSV", systemImage: "tablecells")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.navy)
          }
        }

        Divider().overlay(AppTheme.warmGray.opacity(0.25))

        ManualCostEntryCard(store: manualCostStore)
      }
    }
  }

  private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(AppTheme.warmGray)
      TextField(title, text: text)
        .keyboardType(keyboard)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(AppTheme.navy)
    }
  }
}

// MARK: - Gömülü yapı denetim kartı

private struct DashboardInspectionSection: View {
  @ObservedObject var viewModel: InspectionViewModel

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
          Text("Yapı Denetim Hesaplama")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
          ConstructionHardHatIcon(size: 34)
          Spacer(minLength: 0)
        }

        Text("\(viewModel.feeTable.count) kayıt (cihazda)")
          .font(.caption)
          .foregroundStyle(AppTheme.warmGray)

        Picker("Bina grubu", selection: $viewModel.buildingGroup) {
          ForEach(viewModel.buildingGroups, id: \.self) { g in
            Text(g).tag(g)
          }
        }
        .pickerStyle(.segmented)

        VStack(alignment: .leading, spacing: 4) {
          Text("Toplam inşaat alanı (m²)").font(.caption).foregroundStyle(AppTheme.warmGray)
          TextField("m²", text: $viewModel.areaText)
            .keyboardType(.decimalPad)
            .padding(12)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        Button("Ücreti hesapla") { viewModel.calculate() }
          .buttonStyle(.borderedProminent)
          .tint(AppTheme.gold)
          .frame(maxWidth: .infinity)

        if let error = viewModel.errorMessage {
          Text(error).font(.caption).foregroundStyle(.red)
        }

        if let result = viewModel.result {
          Text(MoneyFormatter.formatTRY(result.fee.feeTry))
            .font(.title2.bold())
            .foregroundStyle(AppTheme.gold)
          Text("Grup: \(result.buildingGroup) • Alan: \(MoneyFormatter.formatAmount(result.areaM2)) m²")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
        }
      }
    }
  }
}

// MARK: - Canlı malzeme + manuel kalem

struct LiveMaterialPricesCard: View {
  let snapshot: MaterialPriceSnapshot
  let isRefreshing: Bool

  @State private var pulse = false

  private var betonProgress: Double { min(snapshot.betonM3Fiyat / 6000, 1) }
  private var demirProgress: Double { min(snapshot.demirTonFiyat / 50000, 1) }

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .center, spacing: 0) {
          Text("Canlı Malzeme Fiyatları")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
            .fixedSize(horizontal: true, vertical: false)

          AnimatedConstructionTruck()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .padding(.trailing, 8)

          if isRefreshing {
            ProgressView().tint(AppTheme.gold)
          } else {
            Image(systemName: "arrow.triangle.2.circlepath")
              .foregroundStyle(AppTheme.gold)
              .rotationEffect(.degrees(pulse ? 360 : 0))
              .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: pulse)
          }
        }

        if let city = snapshot.cityLabel {
          Text("\(city) • \(relativeUpdateText)")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
        } else {
          Text(relativeUpdateText).font(.caption).foregroundStyle(AppTheme.warmGray)
        }

        HStack(spacing: 14) {
          materialTile(title: "Beton", unit: "m³", price: snapshot.betonM3Fiyat, progress: betonProgress, source: snapshot.betonSource, icon: "cube.fill")
          materialTile(title: "Demir", unit: "ton", price: snapshot.demirTonFiyat, progress: demirProgress, source: snapshot.demirSource, icon: "square.stack.3d.up.fill")
        }
      }
    }
    .onAppear { pulse = true }
  }

  private var relativeUpdateText: String {
    let seconds = Int(Date().timeIntervalSince(snapshot.updatedAt))
    if seconds < 60 { return "Az önce güncellendi" }
    if seconds < 3600 { return "\(seconds / 60) dk önce" }
    return "\(seconds / 3600) sa önce"
  }

  private func materialTile(title: String, unit: String, price: Double, progress: Double, source: String, icon: String) -> some View {
    VStack(spacing: 8) {
      ZStack {
        CircularGaugeView(progress: progress, lineWidth: 9).frame(width: 72, height: 72)
        Image(systemName: icon).font(.caption).foregroundStyle(AppTheme.gold)
      }
      Text(title).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.warmGray)
      Text(MoneyFormatter.formatTRY(price)).font(.subheadline.bold()).foregroundStyle(AppTheme.charcoal)
      Text("/ \(unit)").font(.caption2).foregroundStyle(AppTheme.warmGray)
      Text(source).font(.caption2).foregroundStyle(AppTheme.warmGray).lineLimit(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous).fill(Color.white.opacity(0.45)))
  }
}

struct ManualCostEntryCard: View {
  @ObservedObject var store: ManualCostStore

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Ek Gider Kalemleri")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.navy)
          Text("İşçilik, nakliye ve diğer giderler")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
        }
        Spacer()
        Button { store.addItem() } label: {
          Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(AppTheme.gold)
        }
        .buttonStyle(.plain)
      }

      if store.items.isEmpty {
        Text("Henüz kalem yok.")
          .font(.caption)
          .foregroundStyle(AppTheme.warmGray)
      } else {
        ForEach($store.items) { $item in
          manualRow(item: $item)
        }
      }

      HStack {
        Text("Ara toplam").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.warmGray)
        Spacer()
        Text(MoneyFormatter.formatTRY(store.totalTry)).font(.subheadline.bold())
      }
    }
  }

  private func manualRow(item: Binding<ManualCostItem>) -> some View {
    HStack(spacing: 8) {
      TextField("Kalem", text: item.title)
        .padding(10)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      TextField("0,00", value: item.amountTry, format: .number.precision(.fractionLength(2)))
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 100)
        .padding(10)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onChange(of: item.wrappedValue.amountTry) { _ in store.updateItem(item.wrappedValue) }
        .onChange(of: item.wrappedValue.title) { _ in store.updateItem(item.wrappedValue) }
      Button { store.removeItem(id: item.wrappedValue.id) } label: {
        Image(systemName: "trash").foregroundStyle(.red.opacity(0.75))
      }
      .buttonStyle(.plain)
    }
  }
}

// MARK: - Sabit üst bar

private struct DashboardFixedHeader: View {
  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      SantiyeAsistLogoMark(size: 48)

      Text("Şantiye Asist")
        .font(.title2.bold())
        .foregroundStyle(AppTheme.navy)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background {
      Rectangle()
        .fill(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(AppTheme.gold.opacity(0.2))
            .frame(height: 1)
        }
    }
  }
}
