import Foundation

/// Kullanıcının elle girdiği malzeme fiyatları — canlı feed bunların üzerine yazmaz.
@MainActor
final class MaterialPriceOverridesStore: ObservableObject {
  static let shared = MaterialPriceOverridesStore()

  static let liveBetonKey = "concrete_c30"
  static let liveRebarKey = "rebar"

  @Published private(set) var overrides: [String: Double] = [:]

  private let cacheKey = "material_price_manual_overrides"

  private init() {
    overrides = LocalCacheService.shared.load([String: Double].self, forKey: cacheKey) ?? [:]
  }

  func isOverridden(_ id: String) -> Bool {
    overrides[id] != nil
  }

  func price(for id: String) -> Double? {
    overrides[id]
  }

  func set(id: String, price: Double) {
    guard price > 0 else {
      remove(id: id)
      return
    }
    overrides[id] = price
    persist()
  }

  func remove(id: String) {
    guard overrides.removeValue(forKey: id) != nil else { return }
    persist()
  }

  func apply(to snapshot: MaterialPriceSnapshot) -> MaterialPriceSnapshot {
    var beton = snapshot.betonM3Fiyat
    var demir = snapshot.demirTonFiyat
    var betonSource = snapshot.betonSource
    var demirSource = snapshot.demirSource

    if let manualBeton = overrides[Self.liveBetonKey] {
      beton = manualBeton
      betonSource = "Manuel"
    }
    if let manualDemir = overrides[Self.liveRebarKey] {
      demir = manualDemir
      demirSource = "Manuel"
    }

    return MaterialPriceSnapshot(
      betonM3Fiyat: beton,
      demirTonFiyat: demir,
      updatedAt: snapshot.updatedAt,
      demirSource: demirSource,
      betonSource: betonSource,
      cityLabel: snapshot.cityLabel
    )
  }

  private func persist() {
    LocalCacheService.shared.save(overrides, forKey: cacheKey)
  }
}
