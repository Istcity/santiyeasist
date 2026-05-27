import Foundation

@MainActor
final class CostCalculatorViewModel: ObservableObject {
    @Published var projectName = "Şantiye Projesi"
    @Published var landAreaText = "900"
    @Published var footprintText = "180"
    @Published var floorCountText = "4"

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

    func calculate(manualItems: [ManualCostItem]) {
        validationError = nil
        result = nil

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
            projectName: projectName.trimmingCharacters(in: .whitespaces),
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
        AppSettings.shared.triggerHaptic(.medium)
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
        result = nil
        validationError = nil
        isCalculating = false
        manualCostStore.resetAll()
    }
    
    func shareCSV() {
        guard let result else { return }
        CSVExportService.shareCSV(result: result)
    }
}
