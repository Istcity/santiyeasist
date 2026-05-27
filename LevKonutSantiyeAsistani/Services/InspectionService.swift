import Foundation

enum InspectionService {
    static func loadFeeTable() -> [InspectionFee] {
        guard let url = Bundle.main.url(
            forResource: "default_inspection_fees",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let list = try? JSONDecoder().decode([InspectionFee].self, from: data) else {
            return defaultTable()
        }
        return list
    }

    static func calculate(
        areaM2: Double,
        buildingGroup: String,
        table: [InspectionFee]
    ) -> InspectionResult? {
        guard let fee = table.first(where: {
            $0.buildingGroup == buildingGroup && $0.matches(area: areaM2)
        }) else { return nil }

        return InspectionResult(
            fee: fee,
            areaM2: areaM2,
            buildingGroup: buildingGroup
        )
    }

    private static func defaultTable() -> [InspectionFee] {
        [
            InspectionFee(buildingGroup: "I-A", minAreaM2: 0, maxAreaM2: 500, feeTry: 18500, year: 2025),
            InspectionFee(buildingGroup: "II-B", minAreaM2: 0, maxAreaM2: 500, feeTry: 22000, year: 2025),
            InspectionFee(buildingGroup: "III-C", minAreaM2: 0, maxAreaM2: 500, feeTry: 26500, year: 2025),
        ]
    }
}
