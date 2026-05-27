import SwiftUI
import FirebaseCore

@main
struct LevKonutApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var projectStore = ProjectStore.shared
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var rewardedAdService = RewardedAdService.shared
    @State private var isBootstrapped = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
        MorningBriefingBackgroundRefresh.register()
        NotificationService.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isBootstrapped {
                    if appSettings.hasCompletedOnboarding {
                        MainTabView()
                            .environmentObject(appState)
                            .environmentObject(AdCoordinator.shared)
                            .environmentObject(projectStore)
                            .environmentObject(appSettings)
                            .environmentObject(rewardedAdService)
                    } else {
                        OnboardingView()
                            .environmentObject(appSettings)
                    }
                } else {
                    ZStack {
                        AppTheme.backgroundGradient.ignoresSafeArea()
                        VStack(spacing: 20) {
                            SantiyeAsistLogoMark(size: 80)
                            ProgressView("Yükleniyor…")
                                .tint(AppTheme.gold)
                        }
                    }
                }
            }
            .preferredColorScheme(.light)
            .task {
                await AdsBootstrap.configure()
                AdManagerService.shared.preloadInterstitial()
                RewardedAdService.shared.preload()
                isBootstrapped = true
                await NotificationService.refreshDailyMorningBriefing()
                MorningBriefingBackgroundRefresh.scheduleNextRefresh()
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .background else { return }
                Task {
                    await NotificationService.refreshDailyMorningBriefing()
                    MorningBriefingBackgroundRefresh.scheduleNextRefresh()
                }
            }
        }
    }
}
