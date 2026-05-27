import SwiftUI

struct PuantajView: View {
  @ObservedObject private var store = ProjectStore.shared
  @State private var selectedDate = Date()
  @State private var showingAddSheet = false

  private var project: SantiyeProject? { store.activeProject }

  private var recordsForDate: [PuantajRecord] {
    guard let project else { return [] }
    return project.puantajRecords.filter {
      Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
    }
  }

  private var totalWorkersForDate: Int {
    recordsForDate.reduce(0) { $0 + $1.workerCount }
  }

  private var totalAdamGunForDate: Double {
    recordsForDate.reduce(0.0) { $0 + $1.adamGun }
  }

  private var monthlyAdamGun: Double {
    guard let project else { return 0 }
    let cal = Calendar.current
    return project.puantajRecords
      .filter { cal.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
      .reduce(0.0) { $0 + $1.adamGun }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        if let _ = project {
          ScrollView {
            VStack(spacing: 16) {
              datePickerCard
              dailySummaryCard
              recordsList
              monthlySummaryCard
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
          }
          .dismissKeyboardOnTap()
        } else {
          noProjectView
        }
      }
      .navigationTitle("Puantaj")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showingAddSheet = true
          } label: {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundStyle(AppTheme.gold)
          }
          .disabled(project == nil)
        }
      }
      .sheet(isPresented: $showingAddSheet) {
        AddPuantajSheet(date: selectedDate)
      }
    }
  }

  // MARK: - Date Picker

  private var datePickerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
          Image(systemName: "calendar")
            .foregroundStyle(AppTheme.gold)
          Text("Tarih Seçin")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }
        DatePicker(
          "Tarih",
          selection: $selectedDate,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .tint(AppTheme.gold)
        .environment(\.locale, Locale(identifier: "tr_TR"))
      }
    }
  }

  // MARK: - Daily Summary

  private var dailySummaryCard: some View {
    GlassCard {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Günlük Özet")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
          Text(selectedDate, style: .date)
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        Spacer()
        VStack(spacing: 4) {
          Text("\(totalWorkersForDate)")
            .font(.title2.weight(.bold))
            .foregroundStyle(AppTheme.navy)
          Text("İşçi")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(width: 70)
        VStack(spacing: 4) {
          Text(String(format: "%.1f", totalAdamGunForDate))
            .font(.title2.weight(.bold))
            .foregroundStyle(AppTheme.gold)
          Text("Adam-Gün")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(width: 80)
      }
    }
  }

  // MARK: - Records

  private var recordsList: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "person.3.fill")
            .foregroundStyle(AppTheme.gold)
          Text("Kayıtlar")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }

        if recordsForDate.isEmpty {
          Text("Bu tarihte kayıt yok.")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
        } else {
          ForEach(recordsForDate) { record in
            GlassInsetTile {
              VStack(alignment: .leading, spacing: 6) {
                HStack {
                  Text(record.teamName.isEmpty ? "Ekip" : record.teamName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                  Spacer()
                  Text(String(format: "%.1f adam-gün", record.adamGun))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                }
                HStack(spacing: 16) {
                  Label("\(record.workerCount) kişi", systemImage: "person.fill")
                  Label(String(format: "%.1f saat", record.hoursWorked), systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

                if !record.workDescription.isEmpty {
                  Text(record.workDescription)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }
              }
            }
          }
          .onDelete { offsets in
            deleteRecords(at: offsets)
          }
        }
      }
    }
  }

  // MARK: - Monthly Summary

  private var monthlySummaryCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "chart.bar.fill")
            .foregroundStyle(AppTheme.gold)
          Text("Aylık Özet")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
          Spacer()
        }

        GlassInsetTile {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(monthLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
              Text("Toplam Adam-Gün")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text(String(format: "%.1f", monthlyAdamGun))
              .font(.title.weight(.bold))
              .foregroundStyle(AppTheme.gold)
          }
        }

        RewardedAdButton(feature: .puantaj, action: {}) {
          HStack {
            Image(systemName: "doc.text.fill")
            Text("Aylık Rapor")
              .font(.subheadline.weight(.semibold))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.navy)
      }
    }
  }

  private var noProjectView: some View {
    VStack(spacing: 16) {
      Image(systemName: "person.3")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))
      Text("Aktif proje yok")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("Puantaj takibi için bir proje seçin")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }

  private var monthLabel: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: selectedDate)
  }

  private func deleteRecords(at offsets: IndexSet) {
    guard var proj = store.activeProject else { return }
    let idsToRemove = offsets.map { recordsForDate[$0].id }
    proj.puantajRecords.removeAll { idsToRemove.contains($0.id) }
    store.activeProject = proj
  }
}

// MARK: - Add Sheet

private struct AddPuantajSheet: View {
  @ObservedObject private var store = ProjectStore.shared
  @Environment(\.dismiss) private var dismiss

  let date: Date
  @State private var teamName = ""
  @State private var workerCount = 1
  @State private var hoursWorked = 8.0
  @State private var description = ""

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            GlassCard {
              VStack(alignment: .leading, spacing: 14) {
                Text("Ekip Adı")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                TextField("Ekip adı", text: $teamName)
                  .textFieldStyle(.plain)
                  .padding(12)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))

                Text("İşçi Sayısı")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                Stepper("\(workerCount) kişi", value: $workerCount, in: 1...200)

                Text("Çalışma Saati")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                HStack {
                  Slider(value: $hoursWorked, in: 1...16, step: 0.5)
                    .tint(AppTheme.gold)
                  Text(String(format: "%.1f sa", hoursWorked))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 55)
                }

                Text("Açıklama")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                TextField("Yapılan iş", text: $description)
                  .textFieldStyle(.plain)
                  .padding(12)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
              }
            }

            GlassInsetTile {
              HStack {
                Text("Adam-Gün:")
                  .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(String(format: "%.1f", Double(workerCount) * hoursWorked / 8.0))
                  .font(.headline)
                  .foregroundStyle(AppTheme.gold)
              }
            }
            .padding(.horizontal, 4)

            Button {
              addRecord()
            } label: {
              Text("Kaydet")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.gold)
          }
          .padding()
        }
      }
      .navigationTitle("Yeni Puantaj Kaydı")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("İptal") { dismiss() }
            .foregroundStyle(AppTheme.navy)
        }
      }
    }
  }

  private func addRecord() {
    guard var proj = store.activeProject else { return }
    var record = PuantajRecord(
      teamName: teamName.isEmpty ? "Ekip" : teamName,
      workerCount: workerCount,
      workDescription: description,
      hoursWorked: hoursWorked
    )
    record.date = date
    proj.puantajRecords.append(record)
    store.activeProject = proj
    dismiss()
  }
}
