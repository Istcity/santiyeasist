import Foundation
import Combine

@MainActor
final class ProjectStore: ObservableObject {
  static let shared = ProjectStore()

  @Published var projects: [SantiyeProject] = []
  @Published var activeProjectID: UUID?

  private let projectsKey = "santiye_projects"
  private let activeIDKey = "santiye_active_project_id"

  var activeProject: SantiyeProject? {
    get { projects.first { $0.id == activeProjectID } }
    set {
      guard let newValue, let idx = projects.firstIndex(where: { $0.id == newValue.id }) else { return }
      projects[idx] = newValue
      persist()
    }
  }

  private init() { load() }

  func load() {
    projects = LocalCacheService.shared.load([SantiyeProject].self, forKey: projectsKey) ?? []
    if let idString = UserDefaults.standard.string(forKey: activeIDKey) {
      activeProjectID = UUID(uuidString: idString)
    }
    if activeProjectID == nil, let first = projects.first {
      activeProjectID = first.id
    }
  }

  func addProject(_ project: SantiyeProject) {
    projects.append(project)
    if activeProjectID == nil { activeProjectID = project.id }
    persist()
  }

  func deleteProject(id: UUID) {
    projects.removeAll { $0.id == id }
    if activeProjectID == id {
      activeProjectID = projects.first?.id
    }
    if UserDefaults.standard.string(forKey: "dashboard_linked_project_id") == id.uuidString {
      UserDefaults.standard.removeObject(forKey: "dashboard_linked_project_id")
      UserDefaults.standard.set(false, forKey: "dashboard_project_name_locked")
    }
    persist()
  }

  func setActive(id: UUID) {
    guard projects.contains(where: { $0.id == id }) else { return }
    activeProjectID = id
    UserDefaults.standard.set(id.uuidString, forKey: activeIDKey)
  }

  func updateProject(_ project: SantiyeProject) {
    guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
    var updated = project
    updated.updatedAt = Date()
    projects[idx] = updated
    persist()
  }

  /// Ana sayfa maliyet hesabını projeye yazar veya günceller.
  @discardableResult
  func saveDashboardCost(
    name: String,
    landAreaM2: Double,
    footprintM2: Double,
    floorCount: Int,
    buildingType: BuildingType,
    kdvPercent: Double,
    karMarjiPercent: Double,
    customUnitPrices: [String: Double],
    manualItems: [ManualCostItem],
    result: CostCalculationResult,
    materialSnapshot: MaterialPriceSnapshot,
    currency: CurrencyRates,
    existingProjectID: UUID?
  ) -> SantiyeProject {
    let calculation = SavedCalculation(
      from: result,
      betonPrice: materialSnapshot.betonM3Fiyat,
      demirPrice: materialSnapshot.demirTonFiyat,
      currency: currency
    )
    let snapshot = ProjectCurrencySnapshot(from: currency)

    var project: SantiyeProject
    if let existingProjectID,
       let idx = projects.firstIndex(where: { $0.id == existingProjectID }) {
      project = projects[idx]
    } else {
      project = SantiyeProject(name: name, buildingType: buildingType)
    }

    project.name = name
    project.buildingType = buildingType
    project.landAreaM2 = landAreaM2
    project.footprintM2 = footprintM2
    project.floorCount = floorCount
    project.kdvPercent = kdvPercent
    project.karMarjiPercent = karMarjiPercent
    project.customUnitPrices = customUnitPrices
    project.manualItems = manualItems
    project.lastCurrencySnapshot = snapshot
    project.savedCalculations.insert(calculation, at: 0)
    if project.savedCalculations.count > 30 {
      project.savedCalculations = Array(project.savedCalculations.prefix(30))
    }

    if let existingProjectID,
       projects.contains(where: { $0.id == existingProjectID }) {
      updateProject(project)
    } else {
      addProject(project)
    }
    setActive(id: project.id)
    return project
  }

  private func persist() {
    LocalCacheService.shared.save(projects, forKey: projectsKey)
    if let id = activeProjectID {
      UserDefaults.standard.set(id.uuidString, forKey: activeIDKey)
    }
  }
}
