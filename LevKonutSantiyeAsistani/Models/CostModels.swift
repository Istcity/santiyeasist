import Foundation
import Combine

struct UnitPrice: Codable, Identifiable {
    let id: String
    let name: String
    let unit: String
    let priceTry: Double
}

struct CostLineItem: Identifiable {
    let id = UUID()
    let label: String
    let quantity: Double
    let unit: String
    let unitPriceTry: Double
    let totalTry: Double
    let note: String?
}

struct CostCalculationResult {
    let projectName: String
    let landAreaM2: Double
    let footprintM2: Double
    let floorCount: Int
    let totalBuildAreaM2: Double
    let lineItems: [CostLineItem]
    let totalCostTry: Double
    let costPerM2Try: Double
    let manualItems: [ManualCostItem]
    let manualTotalTry: Double
    let kdvAmount: Double
    let karMarjiAmount: Double

    var grandTotalTry: Double { totalCostTry + manualTotalTry + kdvAmount + karMarjiAmount }
    
    init(projectName: String, landAreaM2: Double, footprintM2: Double, floorCount: Int,
         totalBuildAreaM2: Double, lineItems: [CostLineItem], totalCostTry: Double,
         costPerM2Try: Double, manualItems: [ManualCostItem], manualTotalTry: Double,
         kdvAmount: Double = 0, karMarjiAmount: Double = 0) {
        self.projectName = projectName
        self.landAreaM2 = landAreaM2
        self.footprintM2 = footprintM2
        self.floorCount = floorCount
        self.totalBuildAreaM2 = totalBuildAreaM2
        self.lineItems = lineItems
        self.totalCostTry = totalCostTry
        self.costPerM2Try = costPerM2Try
        self.manualItems = manualItems
        self.manualTotalTry = manualTotalTry
        self.kdvAmount = kdvAmount
        self.karMarjiAmount = karMarjiAmount
    }
}

struct ManualCostItem: Identifiable, Codable, Equatable {
  var id: UUID
  var title: String
  var amountTry: Double

  init(id: UUID = UUID(), title: String, amountTry: Double) {
    self.id = id
    self.title = title
    self.amountTry = amountTry
  }
}

struct MaterialPriceSnapshot: Equatable, Codable {
  let betonM3Fiyat: Double
  let demirTonFiyat: Double
  let updatedAt: Date
  let demirSource: String
  let betonSource: String
  let cityLabel: String?
}

@MainActor
final class ManualCostStore: ObservableObject {
  static let shared = ManualCostStore()

  @Published var items: [ManualCostItem] = []

  private let cacheKey = "manual_cost_items"

  private init() {
    load()
  }

  var totalTry: Double {
    items.reduce(0) { $0 + max(0, $1.amountTry) }
  }

  func load() {
    items = LocalCacheService.shared.load([ManualCostItem].self, forKey: cacheKey) ?? []
  }

  func addItem(title: String = "Yeni kalem", amountTry: Double = 0) {
    items.append(ManualCostItem(title: title, amountTry: amountTry))
    persist()
  }

  func updateItem(_ item: ManualCostItem) {
    guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
    items[index] = item
    persist()
  }

  func removeItem(id: UUID) {
    items.removeAll { $0.id == id }
    persist()
  }

  func resetAll() {
    items = []
    persist()
  }

  func replaceItems(_ newItems: [ManualCostItem]) {
    items = newItems
    persist()
  }

  private func persist() {
    LocalCacheService.shared.save(items, forKey: cacheKey)
  }
}
