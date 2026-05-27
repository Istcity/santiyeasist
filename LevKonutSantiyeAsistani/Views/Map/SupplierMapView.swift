import SwiftUI
import MapKit

struct SupplierMapView: View {
  @ObservedObject private var rewardedService = RewardedAdService.shared
  @ObservedObject private var settings = AppSettings.shared

  @State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
  )
  @State private var selectedCategory: SupplierCategory = .readyMix
  @State private var annotations: [SupplierAnnotation] = []
  @State private var isSearching = false

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        if rewardedService.isFeatureUnlocked(.supplierMap) {
          mapContent
        } else {
          lockedView
        }
      }
      .navigationTitle("Tedarikçiler")
    }
  }

  // MARK: - Map Content

  private var mapContent: some View {
    VStack(spacing: 0) {
      categoryFilters
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)

      Map(coordinateRegion: $region, annotationItems: annotations) { pin in
        MapAnnotation(coordinate: pin.coordinate) {
          VStack(spacing: 2) {
            Image(systemName: pin.category.icon)
              .font(.caption)
              .foregroundStyle(.white)
              .padding(6)
              .background(Circle().fill(pin.category.color))
              .shadow(radius: 3)
            Text(pin.name)
              .font(.system(size: 9, weight: .medium))
              .foregroundStyle(AppTheme.textPrimary)
              .lineLimit(1)
              .padding(.horizontal, 4)
              .padding(.vertical, 2)
              .background(Color.white.opacity(0.85))
              .clipShape(Capsule())
          }
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .overlay(alignment: .topTrailing) {
        if isSearching {
          ProgressView()
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .padding()
        }
      }
    }
    .onAppear { searchSuppliers() }
    .onChange(of: selectedCategory) { _ in searchSuppliers() }
  }

  // MARK: - Category Filters

  private var categoryFilters: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(SupplierCategory.allCases) { category in
          Button {
            selectedCategory = category
          } label: {
            HStack(spacing: 6) {
              Image(systemName: category.icon)
                .font(.caption)
              Text(category.label)
                .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
              selectedCategory == category
                ? AppTheme.gold
                : Color.white.opacity(0.55)
            )
            .foregroundStyle(
              selectedCategory == category
                ? .white
                : AppTheme.textPrimary
            )
            .clipShape(Capsule())
          }
        }
      }
    }
  }

  // MARK: - Locked View

  private var lockedView: some View {
    VStack(spacing: 20) {
      Image(systemName: "map.fill")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))

      Text("Tedarikçi Haritası")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)

      Text("Yakınındaki beton santralleri, demir bayileri ve yapı marketleri haritada gör.")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      RewardedAdButton(feature: .supplierMap, action: {}) {
        HStack {
          Image(systemName: "lock.open.fill")
          Text("Haritayı Aç")
            .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
      }
      .buttonStyle(.borderedProminent)
      .tint(AppTheme.gold)
      .padding(.horizontal, 40)
    }
  }

  // MARK: - Search

  private func searchSuppliers() {
    isSearching = true
    annotations = []

    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = selectedCategory.searchQuery
    request.region = region

    let search = MKLocalSearch(request: request)
    search.start { response, _ in
      DispatchQueue.main.async {
        isSearching = false
        guard let items = response?.mapItems else { return }
        annotations = items.prefix(20).map { item in
          SupplierAnnotation(
            name: item.name ?? "Bilinmiyor",
            coordinate: item.placemark.coordinate,
            category: selectedCategory
          )
        }
      }
    }
  }
}

// MARK: - Models

enum SupplierCategory: String, CaseIterable, Identifiable {
  case readyMix, rebarDealer, buildingMarket

  var id: String { rawValue }

  var label: String {
    switch self {
    case .readyMix: return "Hazır Beton"
    case .rebarDealer: return "Demir Bayi"
    case .buildingMarket: return "Yapı Market"
    }
  }

  var icon: String {
    switch self {
    case .readyMix: return "drop.circle.fill"
    case .rebarDealer: return "cylinder.split.1x2.fill"
    case .buildingMarket: return "cart.fill"
    }
  }

  var color: Color {
    switch self {
    case .readyMix: return AppTheme.navy
    case .rebarDealer: return AppTheme.gold
    case .buildingMarket: return Color.orange
    }
  }

  var searchQuery: String {
    switch self {
    case .readyMix: return "hazır beton santral"
    case .rebarDealer: return "demir bayi inşaat demiri"
    case .buildingMarket: return "yapı market"
    }
  }
}

struct SupplierAnnotation: Identifiable {
  let id = UUID()
  let name: String
  let coordinate: CLLocationCoordinate2D
  let category: SupplierCategory
}
