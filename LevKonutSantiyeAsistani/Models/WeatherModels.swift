import Foundation

struct WeatherForecastItem: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let tempC: Double
    let tempMinC: Double
    let tempMaxC: Double
    let humidity: Int
    let windSpeedKmh: Double
    let precipitationProbability: Double
    let description: String
}

struct WeatherBundle: Codable {
    let location: GeoLocation
    let cityName: String
    let items: [WeatherForecastItem]
    let fetchedAt: Date

    var threeDayForecast: [DailyWeatherSummary] {
        let calendar = Calendar.current
        var grouped: [Date: [WeatherForecastItem]] = [:]
        for item in items {
            let day = calendar.startOfDay(for: item.date)
            grouped[day, default: []].append(item)
        }

        return grouped.keys.sorted().prefix(3).compactMap { day in
            guard let dayItems = grouped[day], !dayItems.isEmpty else { return nil }
            let minC = dayItems.map(\.tempMinC).min() ?? 0
            let maxC = dayItems.map(\.tempMaxC).max() ?? 0
            let rain = dayItems.map(\.precipitationProbability).max() ?? 0
            let description = dayItems.first?.description ?? ""
            return DailyWeatherSummary(
                date: day,
                minC: minC,
                maxC: maxC,
                precipitationProbability: rain,
                description: description
            )
        }
    }
}

struct DailyWeatherSummary: Identifiable {
    var id: Date { date }
    let date: Date
    let minC: Double
    let maxC: Double
    let precipitationProbability: Double
    let description: String

    var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }
}

struct ConstructionAdvice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: AdviceSeverity
    let relatedDate: Date

    enum AdviceSeverity {
        case info, warning, critical
    }
}
