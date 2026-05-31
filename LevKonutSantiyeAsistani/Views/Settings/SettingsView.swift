import SwiftUI
import UserNotifications

struct SettingsView: View {
  @ObservedObject private var settings = AppSettings.shared
  @ObservedObject private var rewardedService = RewardedAdService.shared
  @State private var showingAlertForm = false
  @State private var alertMaterial = "Demir"
  @State private var alertPrice = ""
  @State private var alertDirection: PriceAlert.AlertDirection = .below
  @State private var notificationStatusText = "Kontrol ediliyor…"

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            generalSection
            notificationsSection
            priceAlertSection
            premiumFeaturesSection
            aboutSection
          }
          .padding()
        }
        .dismissKeyboardOnTap()
      }
      .navigationTitle("Ayarlar")
      .navigationBarTitleDisplayMode(.inline)
      .task { await refreshNotificationStatus() }
    }
  }

  private var generalSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        Text("Genel")
          .font(.headline)
          .foregroundStyle(AppTheme.navy)

        VStack(alignment: .leading, spacing: 4) {
          Text("Varsayılan Şehir")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
          Picker("Şehir", selection: $settings.defaultCity) {
            ForEach(AppSettings.availableCities, id: \.self) { city in
              Text(city).tag(city)
            }
          }
          .pickerStyle(.menu)
          .tint(AppTheme.gold)
          .onChange(of: settings.defaultCity) { _ in
            guard settings.morningBriefingEnabled else { return }
            Task { await NotificationService.refreshDailyMorningBriefing() }
          }
        }

        Toggle(isOn: $settings.hapticEnabled) {
          Label("Dokunsal Geri Bildirim", systemImage: "hand.tap.fill")
            .foregroundStyle(AppTheme.navy)
        }
        .tint(AppTheme.gold)

        Button {
          settings.hasCompletedOnboarding = false
        } label: {
          Label("Tanıtımı Tekrar Göster", systemImage: "arrow.counterclockwise")
            .font(.subheadline)
            .foregroundStyle(AppTheme.gold)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var notificationsSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        Text("Bildirimler")
          .font(.headline)
          .foregroundStyle(AppTheme.navy)

        Toggle(isOn: $settings.morningBriefingEnabled) {
          Label("Sabah özeti (08:30)", systemImage: "sun.max.fill")
            .foregroundStyle(AppTheme.navy)
        }
        .tint(AppTheme.gold)
        .onChange(of: settings.morningBriefingEnabled) { enabled in
          if enabled {
            NotificationService.requestPermission()
            Task {
              await NotificationService.refreshDailyMorningBriefing()
              MorningBriefingBackgroundRefresh.scheduleNextRefresh()
              await refreshNotificationStatus()
            }
          } else {
            Task { await refreshNotificationStatus() }
          }
        }

        Text(
          "Seçili şehir için hava durumu özeti ve döviz/beton/demir hatırlatması. Arka planda yaklaşık 08:00'de güncellenir."
        )
        .font(.caption2)
        .foregroundStyle(AppTheme.warmGray)

        Text(notificationStatusText)
          .font(.caption.weight(.medium))
          .foregroundStyle(AppTheme.navy)

        HStack(spacing: 10) {
          Button {
            NotificationService.requestPermission()
            Task { await refreshNotificationStatus() }
          } label: {
            Text("İzin iste")
              .font(.caption.weight(.semibold))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .tint(AppTheme.gold)

          Button {
            Task {
              await NotificationService.refreshDailyMorningBriefing()
              await refreshNotificationStatus()
            }
          } label: {
            Text("Özeti güncelle")
              .font(.caption.weight(.semibold))
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .tint(AppTheme.navy)
          .disabled(!settings.morningBriefingEnabled)
        }
      }
    }
  }

  private func refreshNotificationStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    notificationStatusText = switch settings.authorizationStatus {
    case .authorized:
      "Sistem bildirim izni: Açık"
    case .provisional:
      "Sistem bildirim izni: Geçici"
    case .denied:
      "Sistem bildirim izni: Kapalı — iOS Ayarlar'dan açın"
    case .notDetermined:
      "Sistem bildirim izni: Henüz istenmedi"
    case .ephemeral:
      "Sistem bildirim izni: Geçici oturum"
    @unknown default:
      "Sistem bildirim izni: Bilinmiyor"
    }
  }

  private var priceAlertSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Text("Fiyat Alarmları")
            .font(.headline)
            .foregroundStyle(AppTheme.navy)
          Spacer()
          Button { showingAlertForm.toggle() } label: {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(AppTheme.gold)
          }
          .buttonStyle(.plain)
        }

        if settings.priceAlerts.isEmpty {
          Text("Henüz alarm yok.")
            .font(.caption)
            .foregroundStyle(AppTheme.warmGray)
        } else {
          ForEach(settings.priceAlerts) { alert in
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(alert.materialName)
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.navy)
                Text("\(MoneyFormatter.formatTRY(alert.targetPrice)) \(alert.direction.rawValue)")
                  .font(.caption)
                  .foregroundStyle(AppTheme.warmGray)
              }
              Spacer()
              Button {
                settings.removePriceAlert(id: alert.id)
              } label: {
                Image(systemName: "trash")
                  .font(.caption)
                  .foregroundStyle(.red.opacity(0.7))
              }
              .buttonStyle(.plain)
            }
          }
        }

        if showingAlertForm {
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Picker("Malzeme", selection: $alertMaterial) {
              Text("Demir").tag("Demir")
              Text("Beton").tag("Beton")
              Text("Çimento").tag("Çimento")
              Text("Kum").tag("Kum")
            }
            .pickerStyle(.segmented)

            TextField("Hedef fiyat (₺)", text: $alertPrice)
              .keyboardType(.decimalPad)
              .padding(10)
              .background(Color.white.opacity(0.5))
              .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Picker("Yön", selection: $alertDirection) {
              Text("Altına düşünce").tag(PriceAlert.AlertDirection.below)
              Text("Üstüne çıkınca").tag(PriceAlert.AlertDirection.above)
            }
            .pickerStyle(.segmented)

            Button("Alarm Ekle") {
              let price = Double(alertPrice.replacingOccurrences(of: ",", with: ".")) ?? 0
              guard price > 0 else { return }
              settings.addPriceAlert(PriceAlert(
                materialName: alertMaterial,
                targetPrice: price,
                direction: alertDirection
              ))
              alertPrice = ""
              showingAlertForm = false
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.gold)
          }
        }
      }
    }
  }

  private var premiumFeaturesSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        Text("Reklam İzle & Kullan")
          .font(.headline)
          .foregroundStyle(AppTheme.navy)

        Text("Kısa reklam izleyerek premium özellikleri 30 dakika kullanın.")
          .font(.caption)
          .foregroundStyle(AppTheme.warmGray)

        ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
          HStack {
            Image(systemName: feature.icon)
              .foregroundStyle(AppTheme.gold)
              .frame(width: 28)
            Text(feature.displayName)
              .font(.subheadline)
              .foregroundStyle(AppTheme.navy)
            Spacer()
            if rewardedService.isFeatureUnlocked(feature) {
              if let remaining = rewardedService.remainingTime(for: feature) {
                Text("\(Int(remaining / 60)) dk")
                  .font(.caption.bold())
                  .foregroundStyle(AppTheme.gold)
              }
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            } else {
              Image(systemName: "lock.fill")
                .foregroundStyle(AppTheme.warmGray)
            }
          }
        }
      }
    }
  }

  private var aboutSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        Text("Hakkında")
          .font(.headline)
          .foregroundStyle(AppTheme.navy)

        HStack(spacing: 12) {
          SantiyeAsistLogoMark(size: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text("Şantiye Asist")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
            Text(AppSettings.versionLabel)
              .font(.caption)
              .foregroundStyle(AppTheme.warmGray)
          }
        }
      }
    }
  }
}
