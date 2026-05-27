import Foundation

struct ExtendedMaterial: Codable, Identifiable, Equatable {
  let id: String
  let name: String
  let unit: String
  var priceTry: Double
  let category: MaterialCategory
  var updatedAt: Date

  enum MaterialCategory: String, Codable, CaseIterable, Identifiable {
    case yapisal = "Yapısal"
    case tesisat = "Tesisat"
    case kaplama = "Kaplama"
    case diger = "Diğer"

    var id: String { rawValue }

    var icon: String {
      switch self {
      case .yapisal: return "building.2.fill"
      case .tesisat: return "wrench.and.screwdriver.fill"
      case .kaplama: return "paintbrush.fill"
      case .diger: return "shippingbox.fill"
      }
    }
  }

  static var defaults: [ExtendedMaterial] {
    [
      ExtendedMaterial(id: "cimento", name: "Çimento (50 kg)", unit: "torba", priceTry: 210, category: .yapisal, updatedAt: Date()),
      ExtendedMaterial(id: "kum", name: "Kum", unit: "ton", priceTry: 450, category: .yapisal, updatedAt: Date()),
      ExtendedMaterial(id: "cakil", name: "Çakıl", unit: "ton", priceTry: 380, category: .yapisal, updatedAt: Date()),
      ExtendedMaterial(id: "tugla", name: "Tuğla (19'luk)", unit: "adet", priceTry: 8.5, category: .yapisal, updatedAt: Date()),
      ExtendedMaterial(id: "ytong", name: "Ytong Blok", unit: "adet", priceTry: 32, category: .yapisal, updatedAt: Date()),
      ExtendedMaterial(id: "alci", name: "Alçı", unit: "torba", priceTry: 185, category: .kaplama, updatedAt: Date()),
      ExtendedMaterial(id: "boya", name: "Boya (İç Cephe 20L)", unit: "kutu", priceTry: 1800, category: .kaplama, updatedAt: Date()),
      ExtendedMaterial(id: "seramik", name: "Seramik (m²)", unit: "m²", priceTry: 350, category: .kaplama, updatedAt: Date()),
      ExtendedMaterial(id: "pvc_boru", name: "PVC Boru (110mm)", unit: "metre", priceTry: 95, category: .tesisat, updatedAt: Date()),
      ExtendedMaterial(id: "bakir_kablo", name: "NYM Kablo (3x2.5)", unit: "metre", priceTry: 48, category: .tesisat, updatedAt: Date()),
      ExtendedMaterial(id: "ppr_boru", name: "PPR Boru (20mm)", unit: "metre", priceTry: 35, category: .tesisat, updatedAt: Date()),
      ExtendedMaterial(id: "izolasyon", name: "Isı Yalıtım (5cm XPS)", unit: "m²", priceTry: 120, category: .diger, updatedAt: Date()),
      ExtendedMaterial(id: "su_yalitim", name: "Su Yalıtım Membran", unit: "m²", priceTry: 85, category: .diger, updatedAt: Date()),
      ExtendedMaterial(id: "dere_oluk", name: "Alüminyum Yağmur Oluğu", unit: "metre", priceTry: 250, category: .diger, updatedAt: Date()),
    ]
  }
}

@MainActor
final class ExtendedMaterialStore: ObservableObject {
  static let shared = ExtendedMaterialStore()

  @Published var materials: [ExtendedMaterial]

  private let cacheKey = "extended_materials"

  private init() {
    if let saved: [ExtendedMaterial] = LocalCacheService.shared.load([ExtendedMaterial].self, forKey: cacheKey) {
      materials = saved
    } else {
      materials = ExtendedMaterial.defaults
      persist()
    }
  }

  func updatePrice(id: String, newPrice: Double) {
    guard let idx = materials.firstIndex(where: { $0.id == id }) else { return }
    materials[idx].priceTry = newPrice
    materials[idx].updatedAt = Date()
    persist()
  }

  func resetToDefaults() {
    materials = ExtendedMaterial.defaults
    persist()
  }

  private func persist() {
    LocalCacheService.shared.save(materials, forKey: cacheKey)
  }
}
