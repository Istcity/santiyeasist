import Foundation

struct CurrencyRates: Codable {
    let usdToTry: Double
    let eurToTry: Double
    let gbpToTry: Double
    let goldToTry: Double
    let silverToTry: Double
    let fetchedAt: Date
    let isFallback: Bool

    static let fallback = CurrencyRates(
        usdToTry: 33.0,
        eurToTry: 36.0,
        gbpToTry: 42.0,
        goldToTry: 3200.0,
        silverToTry: 38.0,
        fetchedAt: Date(),
        isFallback: true
    )
}
