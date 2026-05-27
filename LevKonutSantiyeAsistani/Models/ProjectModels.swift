import Foundation

struct SantiyeProject: Codable, Identifiable, Equatable {
  var id: UUID
  var name: String
  var buildingType: BuildingType
  var landAreaM2: Double
  var footprintM2: Double
  var floorCount: Int
  var createdAt: Date
  var updatedAt: Date
  var locationCity: String?
  var notes: String

  var customUnitPrices: [String: Double]
  var kdvPercent: Double
  var karMarjiPercent: Double

  var savedCalculations: [SavedCalculation]
  var manualItems: [ManualCostItem]

  var hakedisItems: [HakedisItem]

  var diaryEntries: [DiaryEntry]

  var puantajRecords: [PuantajRecord]

  var totalBuildAreaM2: Double { footprintM2 * Double(floorCount) }

  init(name: String = "Yeni Proje", buildingType: BuildingType = .konut) {
    self.id = UUID()
    self.name = name
    self.buildingType = buildingType
    self.landAreaM2 = 900
    self.footprintM2 = 180
    self.floorCount = 4
    self.createdAt = Date()
    self.updatedAt = Date()
    self.notes = ""
    self.customUnitPrices = [:]
    self.kdvPercent = 20
    self.karMarjiPercent = 0
    self.savedCalculations = []
    self.manualItems = []
    self.hakedisItems = HakedisItem.defaultItems
    self.diaryEntries = []
    self.puantajRecords = []
  }
}

enum BuildingType: String, Codable, CaseIterable, Identifiable {
  case konut = "Konut"
  case ticari = "Ticari"
  case endustriyel = "Endüstriyel"
  case villa = "Villa"

  var id: String { rawValue }

  var costMultiplier: Double {
    switch self {
    case .konut: return 1.0
    case .ticari: return 1.15
    case .endustriyel: return 0.85
    case .villa: return 1.25
    }
  }
}

struct SavedCalculation: Codable, Identifiable, Equatable {
  let id: UUID
  let date: Date
  let grandTotalTry: Double
  let costPerM2Try: Double
  let totalBuildAreaM2: Double
  let betonPrice: Double
  let demirPrice: Double

  init(from result: CostCalculationResult, betonPrice: Double, demirPrice: Double) {
    self.id = UUID()
    self.date = Date()
    self.grandTotalTry = result.grandTotalTry
    self.costPerM2Try = result.costPerM2Try
    self.totalBuildAreaM2 = result.totalBuildAreaM2
    self.betonPrice = betonPrice
    self.demirPrice = demirPrice
  }

  init(id: UUID = UUID(), date: Date = Date(), grandTotalTry: Double, costPerM2Try: Double, totalBuildAreaM2: Double, betonPrice: Double, demirPrice: Double) {
    self.id = id
    self.date = date
    self.grandTotalTry = grandTotalTry
    self.costPerM2Try = costPerM2Try
    self.totalBuildAreaM2 = totalBuildAreaM2
    self.betonPrice = betonPrice
    self.demirPrice = demirPrice
  }
}

struct HakedisItem: Codable, Identifiable, Equatable {
  var id: UUID
  var name: String
  var completionPercent: Double
  var estimatedCostTry: Double

  var completedCostTry: Double { estimatedCostTry * completionPercent / 100 }

  static var defaultItems: [HakedisItem] {
    [
      HakedisItem(id: UUID(), name: "Hafriyat ve Temel", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Kaba İnşaat (Betonarme)", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Duvar İşleri", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Çatı", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Sıva ve Boya", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Elektrik Tesisatı", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Mekanik Tesisat", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Döşeme ve Kaplama", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Doğrama (Kapı/Pencere)", completionPercent: 0, estimatedCostTry: 0),
      HakedisItem(id: UUID(), name: "Çevre Düzenleme", completionPercent: 0, estimatedCostTry: 0),
    ]
  }
}

struct DiaryEntry: Codable, Identifiable, Equatable {
  var id: UUID
  var date: Date
  var note: String
  var photoFileNames: [String]
  var weather: String
  var workerCount: Int

  init(note: String = "", weather: String = "", workerCount: Int = 0) {
    self.id = UUID()
    self.date = Date()
    self.note = note
    self.photoFileNames = []
    self.weather = weather
    self.workerCount = workerCount
  }
}

struct PuantajRecord: Codable, Identifiable, Equatable {
  var id: UUID
  var date: Date
  var teamName: String
  var workerCount: Int
  var workDescription: String
  var hoursWorked: Double

  var adamGun: Double { Double(workerCount) * hoursWorked / 8.0 }

  init(teamName: String = "", workerCount: Int = 0, workDescription: String = "", hoursWorked: Double = 8) {
    self.id = UUID()
    self.date = Date()
    self.teamName = teamName
    self.workerCount = workerCount
    self.workDescription = workDescription
    self.hoursWorked = hoursWorked
  }
}

enum PremiumFeature: String, CaseIterable, Hashable {
  case csvExport = "csv_export"
  case pdfArchive = "pdf_archive"
  case priceAlerts = "price_alerts"
  case unlimitedProjects = "unlimited_projects"
  case puantaj = "puantaj"
  case hakedisReport = "hakedis_report"
  case customUnitPrices = "custom_unit_prices"
  case buildingTypeSelection = "building_type"
  case supplierMap = "supplier_map"
  case advancedWeather = "advanced_weather"

  var displayName: String {
    switch self {
    case .csvExport: return "Excel/CSV Dışa Aktarım"
    case .pdfArchive: return "PDF Arşivi"
    case .priceAlerts: return "Fiyat Alarmları"
    case .unlimitedProjects: return "Sınırsız Proje"
    case .puantaj: return "Puantaj Takibi"
    case .hakedisReport: return "Hakediş Raporu"
    case .customUnitPrices: return "Özel Birim Fiyatlar"
    case .buildingTypeSelection: return "Bina Tipi Seçimi"
    case .supplierMap: return "Tedarikçi Haritası"
    case .advancedWeather: return "Gelişmiş Hava Durumu"
    }
  }

  var icon: String {
    switch self {
    case .csvExport: return "tablecells"
    case .pdfArchive: return "archivebox.fill"
    case .priceAlerts: return "bell.badge.fill"
    case .unlimitedProjects: return "folder.fill.badge.plus"
    case .puantaj: return "person.3.fill"
    case .hakedisReport: return "chart.bar.doc.horizontal.fill"
    case .customUnitPrices: return "slider.horizontal.3"
    case .buildingTypeSelection: return "building.2.fill"
    case .supplierMap: return "map.fill"
    case .advancedWeather: return "cloud.sun.bolt.fill"
    }
  }

  var sessionDurationMinutes: Int { 30 }
}

struct PriceAlert: Codable, Identifiable, Equatable {
  var id: UUID
  var materialName: String
  var targetPrice: Double
  var direction: AlertDirection
  var isActive: Bool
  var triggeredAt: Date?

  enum AlertDirection: String, Codable {
    case below = "altına"
    case above = "üstüne"
  }

  init(materialName: String, targetPrice: Double, direction: AlertDirection) {
    self.id = UUID()
    self.materialName = materialName
    self.targetPrice = targetPrice
    self.direction = direction
    self.isActive = true
    self.triggeredAt = nil
  }
}
