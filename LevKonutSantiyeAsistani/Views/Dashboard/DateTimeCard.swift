import SwiftUI

struct DateTimeCard: View {
  @State private var now = Date()

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  private var dateFormatter: DateFormatter {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.dateFormat = "d MMMM yyyy, EEEE"
    return f
  }

  private var timeFormatter: DateFormatter {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.dateFormat = "HH:mm"
    return f
  }

  var body: some View {
    GlassCard {
      HStack(spacing: 14) {
        Image(systemName: "calendar.badge.clock")
          .font(.title2)
          .foregroundStyle(AppTheme.gold)

        VStack(alignment: .leading, spacing: 2) {
          Text(dateFormatter.string(from: now))
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.navy)
          Text(timeFormatter.string(from: now))
            .font(.title.bold().monospacedDigit())
            .foregroundStyle(AppTheme.gold)
        }

        Spacer()
      }
    }
    .onReceive(timer) { now = $0 }
  }
}
