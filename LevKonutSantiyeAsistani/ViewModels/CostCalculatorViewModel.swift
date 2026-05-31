import Foundation

@MainActor
final class CostCalculatorViewModel: ObservableObject {
    private static let linkedProjectKey = "dashboard_linked_project_id"
    private static let nameLockedKey = "dashboard_project_name_locked"

    @Published var projectName = "Şantiye Projesi"
    @Published var landAreaText = "900"
    @Published var footprintText = "180"
    @Published var floorCountText = "4"
    @Published private(set) var isProjectNameLocked = false
    @Published private(set) var linkedProjectID: UUID?
    @Published private(set) var projectSaveMessage: String?

    @Published private(set) var materialSnapshot: MaterialPriceSnapshot = MaterialPriceSnapshot(
        betonM3Fiyat: AppConfig.defaults.betonM3Fiyat,
        demirTonFiyat: AppConfig.defaults.demirTonFiyat,
        updatedAt: Date(),
        demirSource: "—",
        betonSource: "—",
        cityLabel: nil
    )
    @Published var result: CostCalculationResult?
    @Published private(set) var isCalculating = false
    @Published var validationError: String?

    func applyMaterialSnapshot(_ snapshot: MaterialPriceSnapshot) {
        materialSnapshot = snapshot
    }

    @Published var buildingType: BuildingType = .konut
    @Published var kdvPercent: Double = 0
    @Published var karMarjiPercent: Double = 0
    @Published var customUnitPrices: [String: Double] = [:]

    private let customPricesCacheKey = "cost_custom_unit_prices_v1"

    init() {
        loadCustomUnitPrices()
    }

    func orderedUnitPrices() -> [UnitPrice] {
        let map = UnitPriceService.loadPrices(snapshot: materialSnapshot)
        return UnitPriceService.costLinePriceIDs.compactMap { map[$0] }
    }

    func effectiveUnitPrice(id: String, base: UnitPrice) -> Double {
        if let custom = customUnitPrices[id], custom > 0 { return custom }
        return base.priceTry
    }

    func setUnitPrice(id: String, value: Double) {
        if value > 0 {
            customUnitPrices[id] = value
        } else {
            customUnitPrices.removeValue(forKey: id)
        }
        saveCustomUnitPrices()
    }

    func recalculateIfNeeded(manualItems: [ManualCostItem], currency: CurrencyRates?) {
        guard result != nil else { return }
        calculate(manualItems: manualItems, currency: currency, persistProject: false)
    }

    func syncFromProjectStore(manualCostStore: ManualCostStore) {
        if let idStr = UserDefaults.standard.string(forKey: Self.linkedProjectKey),
           let id = UUID(uuidString: idStr),
           let project = ProjectStore.shared.projects.first(where: { $0.id == id }) {
            linkedProjectID = id
            applyProject(project)
            manualCostStore.replaceItems(project.manualItems)
            isProjectNameLocked = true
            return
        }
        if UserDefaults.standard.bool(forKey: Self.nameLockedKey) {
            isProjectNameLocked = true
        }
    }

    private func loadCustomUnitPrices() {
        guard let data = UserDefaults.standard.data(forKey: customPricesCacheKey),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return }
        customUnitPrices = decoded
    }

    private func saveCustomUnitPrices() {
        guard let data = try? JSONEncoder().encode(customUnitPrices) else { return }
        UserDefaults.standard.set(data, forKey: customPricesCacheKey)
    }

    func calculate(
        manualItems: [ManualCostItem],
        currency: CurrencyRates?,
        persistProject: Bool = true
    ) {
        validationError = nil
        result = nil
        projectSaveMessage = nil

        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Proje adı girin."
            return
        }

        guard let land = Double(landAreaText.replacingOccurrences(of: ",", with: ".")),
              let footprint = Double(footprintText.replacingOccurrences(of: ",", with: ".")),
              let floors = Int(floorCountText),
              land > 0, footprint > 0, floors > 0 else {
            validationError = "Lütfen geçerli sayılar girin."
            return
        }

        isCalculating = true
        let prices = UnitPriceService.loadPrices(snapshot: materialSnapshot)
        result = CostCalculatorService.calculate(
            projectName: trimmedName,
            landAreaM2: land,
            footprintM2: footprint,
            floorCount: floors,
            prices: prices,
            manualItems: manualItems,
            buildingType: buildingType,
            customUnitPrices: customUnitPrices,
            kdvPercent: kdvPercent,
            karMarjiPercent: karMarjiPercent
        )
        isCalculating = false

        guard let result else { return }

        AppSettings.shared.triggerHaptic(.medium)

        if persistProject, let currency {
            let saved = ProjectStore.shared.saveDashboardCost(
                name: trimmedName,
                landAreaM2: land,
                footprintM2: footprint,
                floorCount: floors,
                buildingType: buildingType,
                kdvPercent: kdvPercent,
                karMarjiPercent: karMarjiPercent,
                customUnitPrices: customUnitPrices,
                manualItems: manualItems,
                result: result,
                materialSnapshot: materialSnapshot,
                currency: currency,
                existingProjectID: linkedProjectID
            )
            linkedProjectID = saved.id
            UserDefaults.standard.set(saved.id.uuidString, forKey: Self.linkedProjectKey)
            lockProjectName()
            projectSaveMessage = "Proje kaydedildi — Projeler sekmesinde görüntüleyebilirsiniz."
        } else if persistProject {
            projectSaveMessage = "Hesap tamamlandı. Proje kaydı için döviz kurlarının yüklenmesini bekleyin."
        }
    }

    private func applyProject(_ project: SantiyeProject) {
        projectName = project.name
        buildingType = project.buildingType
        landAreaText = formatAreaInput(project.landAreaM2)
        footprintText = formatAreaInput(project.footprintM2)
        floorCountText = String(project.floorCount)
        kdvPercent = project.kdvPercent
        karMarjiPercent = project.karMarjiPercent
        customUnitPrices = project.customUnitPrices
        saveCustomUnitPrices()
    }

    private func formatAreaInput(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(value)
    }

    private func lockProjectName() {
        isProjectNameLocked = true
        UserDefaults.standard.set(true, forKey: Self.nameLockedKey)
    }

    private func clearDashboardProjectLink() {
        linkedProjectID = nil
        isProjectNameLocked = false
        UserDefaults.standard.removeObject(forKey: Self.linkedProjectKey)
        UserDefaults.standard.set(false, forKey: Self.nameLockedKey)
    }

    func sharePDF() {
        guard let result else { return }
        CostReportPDFService.share(result: result)
    }

    func resetCost(manualCostStore: ManualCostStore) {
        projectName = "Şantiye Projesi"
        landAreaText = "900"
        footprintText = "180"
        floorCountText = "4"
        buildingType = .konut
        kdvPercent = 0
        karMarjiPercent = 0
        customUnitPrices = [:]
        saveCustomUnitPrices()
        result = nil
        validationError = nil
        projectSaveMessage = nil
        isCalculating = false
        clearDashboardProjectLink()
        manualCostStore.resetAll()
    }
    
    func shareCSV() {
        guard let result else { return }
        CSVExportService.shareCSV(result: result)
    }
}
