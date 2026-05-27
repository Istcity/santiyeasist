import SwiftUI

/// yenitarz.jpg referansı: sıcak cam gradyan + lacivert/altın vurgular.
enum AppTheme {
  static let navy = Color(red: 0.04, green: 0.12, blue: 0.23)
  static let navyLight = Color(red: 0.08, green: 0.17, blue: 0.31)
  static let gold = Color(red: 0.83, green: 0.69, blue: 0.22)
  static let goldMuted = Color(red: 0.72, green: 0.59, blue: 0.18)
  static let sand = Color(red: 0.93, green: 0.89, blue: 0.84)
  static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
  static let warmGray = Color(red: 0.55, green: 0.52, blue: 0.48)
  static let charcoal = navy
  static let textPrimary = navy
  static let textSecondary = Color(red: 0.45, green: 0.43, blue: 0.40)

  static let backgroundGradient = LinearGradient(
    colors: [
      Color(red: 0.97, green: 0.94, blue: 0.90),
      Color(red: 0.90, green: 0.87, blue: 0.82),
      Color(red: 0.84, green: 0.86, blue: 0.89),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let cardFill = Color.white.opacity(0.55)
  static let cardStroke = LinearGradient(
    colors: [gold.opacity(0.55), Color.white.opacity(0.35)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  static let cardShadow = Color(red: 0.04, green: 0.12, blue: 0.23).opacity(0.12)

  static let cornerRadiusLarge: CGFloat = 28
  static let cornerRadiusMedium: CGFloat = 20
  static let cornerRadiusSmall: CGFloat = 14

  static let darkBackgroundGradient = LinearGradient(
    colors: [
      Color(red: 0.06, green: 0.08, blue: 0.14),
      Color(red: 0.10, green: 0.13, blue: 0.20),
      Color(red: 0.08, green: 0.10, blue: 0.16),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  static let darkCardFill = Color.white.opacity(0.08)
  static let darkCardStroke = LinearGradient(
    colors: [gold.opacity(0.35), Color.white.opacity(0.12)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}

extension View {
  func santiyeAccessibility(label: String, hint: String = "") -> some View {
    self
      .accessibilityLabel(Text(label))
      .accessibilityHint(Text(hint))
  }

  func dismissKeyboardOnTap() -> some View {
    self.onTapGesture {
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
      )
    }
  }
}

enum MoneyFormatter {
  private static let tryFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.groupingSeparator = "."
    formatter.decimalSeparator = ","
    return formatter
  }()

  private static let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.currencyCode = "TRY"
    formatter.currencySymbol = "₺"
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
  }()

  static func formatTRY(_ value: Double) -> String {
    currencyFormatter.string(from: NSNumber(value: value)) ?? fallback(value)
  }

  static func formatAmount(_ value: Double) -> String {
    tryFormatter.string(from: NSNumber(value: value)) ?? fallback(value)
  }

  static func formatTRYPerUnit(_ value: Double, unit: String) -> String {
    "\(formatTRY(value))/\(unit)"
  }

  private static func fallback(_ value: Double) -> String {
    String(format: "%.2f ₺", value).replacingOccurrences(of: ".", with: ",")
  }
}
