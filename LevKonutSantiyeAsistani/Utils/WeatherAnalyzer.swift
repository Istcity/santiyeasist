import Foundation

enum WeatherAnalyzer {
    static func analyze(_ bundle: WeatherBundle) -> [ConstructionAdvice] {
        var advices: [ConstructionAdvice] = []

        for item in bundle.items {
            if item.tempMinC < 5 {
                advices.append(ConstructionAdvice(
                    title: "Beton dökümü riskli",
                    message: "Minimum \(String(format: "%.1f", item.tempMinC))°C. 5°C altında beton dökümü önerilmez.",
                    severity: .critical,
                    relatedDate: item.date
                ))
            }

            if item.precipitationProbability > 60 {
                advices.append(ConstructionAdvice(
                    title: "Hafriyat ve cephe işleri ertelenmeli",
                    message: "Yağış ihtimali %\(Int(item.precipitationProbability)). Dış cephe ve hafriyatı erteleyin.",
                    severity: .warning,
                    relatedDate: item.date
                ))
            }

            if item.windSpeedKmh > 30 {
                advices.append(ConstructionAdvice(
                    title: "Vinç operasyonu tehlikeli",
                    message: "Rüzgar \(Int(item.windSpeedKmh)) km/saat. Vinç ve iskele operasyonlarını durdurun.",
                    severity: .critical,
                    relatedDate: item.date
                ))
            }
        }

        return advices
    }
}
