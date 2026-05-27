import Foundation

@MainActor
final class InspectionViewModel: ObservableObject {
    @Published var areaText = "720"
    @Published var buildingGroup = "I-A"
    @Published private(set) var feeTable: [InspectionFee] = []
    @Published private(set) var result: InspectionResult?
    @Published var errorMessage: String?

    let buildingGroups = ["I-A", "II-B", "III-C"]

    func load() {
        feeTable = InspectionService.loadFeeTable()
    }

    func calculate() {
        errorMessage = nil
        result = nil

        guard let area = Double(areaText.replacingOccurrences(of: ",", with: ".")),
              area > 0 else {
            errorMessage = "Geçerli bir alan (m²) girin."
            return
        }

        if let match = InspectionService.calculate(
            areaM2: area,
            buildingGroup: buildingGroup,
            table: feeTable
        ) {
            result = match
        } else {
            errorMessage = "Bu grup ve alan için kayıt bulunamadı."
        }
    }
}
