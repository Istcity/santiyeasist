import Foundation

struct InspectionFee: Codable, Identifiable {
    var id: String { "\(buildingGroup)-\(minAreaM2)-\(maxAreaM2)" }
    let buildingGroup: String
    let minAreaM2: Double
    let maxAreaM2: Double
    let feeTry: Double
    let year: Int

    func matches(area: Double) -> Bool {
        area >= minAreaM2 && area <= maxAreaM2
    }
}

struct InspectionResult {
    let fee: InspectionFee
    let areaM2: Double
    let buildingGroup: String
}
