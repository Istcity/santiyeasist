import BackgroundTasks
import Foundation

/// Sabah 08:30 bildiriminden önce hava özetini arka planda günceller.
enum MorningBriefingBackgroundRefresh {
  static let taskIdentifier = "com.levkonut.santiye.morning-briefing-refresh"

  private static let refreshHour = 8
  private static let refreshMinute = 0

  static func register() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: taskIdentifier,
      using: nil
    ) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      perform(refreshTask)
    }
  }

  static func scheduleNextRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
    request.earliestBeginDate = nextRefreshDate()

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Sistem kotası veya zaten planlanmış istek — sessizce yoksay.
    }
  }

  private static func perform(_ task: BGAppRefreshTask) {
    scheduleNextRefresh()

    final class CompletionGate: @unchecked Sendable {
      var finished = false
    }
    let gate = CompletionGate()

    task.expirationHandler = {
      guard !gate.finished else { return }
      gate.finished = true
      task.setTaskCompleted(success: false)
    }

    Task { @MainActor in
      await NotificationService.refreshDailyMorningBriefing(useCachedLocationOnly: true)
      guard !gate.finished else { return }
      gate.finished = true
      task.setTaskCompleted(success: true)
    }
  }

  /// Bir sonraki yerel 08:00 (bildirimden ~30 dk önce).
  static func nextRefreshDate(from reference: Date = Date()) -> Date {
    let calendar = Calendar.current
    var target =
      calendar.date(
        bySettingHour: refreshHour,
        minute: refreshMinute,
        second: 0,
        of: reference
      ) ?? reference

    if target <= reference {
      target = calendar.date(byAdding: .day, value: 1, to: target) ?? target.addingTimeInterval(86400)
    }
    return target
  }
}
