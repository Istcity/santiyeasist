import Foundation

/// Excel V4 formülleri — offline hesap.
enum CostCalculatorService {
    static func calculate(
        projectName: String,
        landAreaM2: Double,
        footprintM2: Double,
        floorCount: Int,
        prices: [String: UnitPrice]
    ) -> CostCalculationResult {
        calculate(
            projectName: projectName,
            landAreaM2: landAreaM2,
            footprintM2: footprintM2,
            floorCount: floorCount,
            prices: prices,
            manualItems: [],
            buildingType: .konut,
            customUnitPrices: [:],
            kdvPercent: 0,
            karMarjiPercent: 0
        )
    }

    static func calculate(
        projectName: String,
        landAreaM2: Double,
        footprintM2: Double,
        floorCount: Int,
        prices: [String: UnitPrice],
        manualItems: [ManualCostItem],
        buildingType: BuildingType = .konut,
        customUnitPrices: [String: Double] = [:],
        kdvPercent: Double = 0,
        karMarjiPercent: Double = 0
    ) -> CostCalculationResult {
        let totalArea = footprintM2 * Double(floorCount)
        let typeMultiplier = buildingType.costMultiplier

        func p(_ id: String, _ fallback: Double) -> Double {
            if let custom = customUnitPrices[id], custom > 0 { return custom }
            return (prices[id]?.priceTry ?? fallback) * typeMultiplier
        }

        let excavationM3 = footprintM2 * 3
        let concreteM3 = totalArea * 0.38
        let rebarTon = totalArea * 45 / 1000
        let wallM2 = totalArea * 1.2

        let items: [CostLineItem] = [
            line("Hafriyat ve Zemin İşleri", excavationM3, "m3", p("excavation", 180), "Taban × 3m"),
            line("Betonarme Betonu", concreteM3, "m3", p("concrete_c30", 3500), "0.38 m³/m²"),
            line("Betonarme Demiri", rebarTon, "Ton", p("rebar", 33000), "45 kg/m²"),
            line("Duvar İşleri", wallM2, "m2", p("wall", 350), "Alanın %120'si"),
            line("Elektrik Tesisatı", totalArea, "m2", p("electrical", 1500), nil),
            line("Mekanik Tesisat", totalArea, "m2", p("mechanical", 1800), nil),
            line("İnce İşler", totalArea, "m2", p("finishing", 4500), nil),
            line("Mühendislik ve İzinler", totalArea, "m2", p("permits", 1200), nil),
        ]

        var total = items.reduce(0) { $0 + $1.totalTry }
        let manualTotal = manualItems.reduce(0) { $0 + max(0, $1.amountTry) }
        
        let subtotal = total + manualTotal
        let kdvAmount = subtotal * kdvPercent / 100
        let karAmount = subtotal * karMarjiPercent / 100

        return CostCalculationResult(
            projectName: projectName,
            landAreaM2: landAreaM2,
            footprintM2: footprintM2,
            floorCount: floorCount,
            totalBuildAreaM2: totalArea,
            lineItems: items,
            totalCostTry: total,
            costPerM2Try: totalArea > 0 ? total / totalArea : 0,
            manualItems: manualItems,
            manualTotalTry: manualTotal,
            kdvAmount: kdvAmount,
            karMarjiAmount: karAmount
        )
    }

    private static func line(
        _ label: String,
        _ qty: Double,
        _ unit: String,
        _ unitPrice: Double,
        _ note: String?
    ) -> CostLineItem {
        CostLineItem(
            label: label,
            quantity: qty,
            unit: unit,
            unitPriceTry: unitPrice,
            totalTry: qty * unitPrice,
            note: note
        )
    }
}
