import SwiftUI

struct ProjectDetailView: View {
  @ObservedObject private var store = ProjectStore.shared
  @Environment(\.dismiss) private var dismiss

  @State private var project: SantiyeProject
  @State private var showDeleteConfirm = false

  private let costKeys = [
    ("excavation", "Hafriyat"),
    ("concrete", "Beton"),
    ("rebar", "Demir"),
    ("wall", "Duvar"),
    ("electrical", "Elektrik"),
    ("mechanical", "Mekanik"),
    ("finishing", "İnce İşler"),
    ("permits", "Harç & Ruhsat"),
  ]

  init(project: SantiyeProject) {
    _project = State(initialValue: project)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient.ignoresSafeArea()

      ScrollView {
        VStack(spacing: 16) {
          projectInfoSection
          customPricesSection
          taxMarginSection
          notesSection
          calculationHistorySection
          deleteSection
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 28)
      }
      .dismissKeyboardOnTap()
    }
    .navigationTitle(project.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Kaydet") { saveAndDismiss() }
          .font(.headline)
          .foregroundStyle(AppTheme.gold)
      }
      ToolbarItem(placement: .navigationBarLeading) {
        Button("İptal") { dismiss() }
          .foregroundStyle(AppTheme.navy)
      }
    }
    .alert("Projeyi Sil", isPresented: $showDeleteConfirm) {
      Button("Sil", role: .destructive) {
        store.deleteProject(id: project.id)
        dismiss()
      }
      Button("İptal", role: .cancel) {}
    } message: {
      Text("'\(project.name)' projesini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
    }
  }

  // MARK: - Sections

  private var projectInfoSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Proje Bilgileri", icon: "info.circle.fill")

        LabeledField(label: "Proje Adı") {
          TextField("Proje adı", text: $project.name)
            .textFieldStyle(.plain)
        }

        Text("Yapı Türü")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(AppTheme.textSecondary)
        Picker("Yapı Türü", selection: $project.buildingType) {
          ForEach(BuildingType.allCases) { type in
            Text(type.rawValue).tag(type)
          }
        }
        .pickerStyle(.segmented)

        HStack(spacing: 12) {
          LabeledField(label: "Arsa (m²)") {
            TextField("m²", value: $project.landAreaM2, format: .number)
              .textFieldStyle(.plain)
              .keyboardType(.decimalPad)
          }
          LabeledField(label: "Taban (m²)") {
            TextField("m²", value: $project.footprintM2, format: .number)
              .textFieldStyle(.plain)
              .keyboardType(.decimalPad)
          }
        }

        LabeledField(label: "Kat Sayısı") {
          Stepper("\(project.floorCount) kat", value: $project.floorCount, in: 1...50)
        }

        GlassInsetTile {
          HStack {
            Image(systemName: "square.stack.3d.up.fill")
              .foregroundStyle(AppTheme.gold)
            Text("Toplam İnşaat Alanı:")
              .font(.subheadline)
              .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(MoneyFormatter.formatAmount(project.totalBuildAreaM2) + " m²")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
          }
        }
      }
    }
  }

  private var customPricesSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Özel Birim Fiyatları", icon: "dollarsign.circle.fill")
        Text("Varsayılanı geçersiz kılmak için aktifleştirin.")
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)

        ForEach(costKeys, id: \.0) { key, label in
          CustomPriceRow(
            label: label,
            key: key,
            customPrices: $project.customUnitPrices
          )
        }
      }
    }
  }

  private var taxMarginSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        sectionHeader("KDV & Kar Marjı", icon: "percent")

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("KDV")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("%\(Int(project.kdvPercent))")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
          }
          Slider(value: $project.kdvPercent, in: 0...30, step: 1)
            .tint(AppTheme.gold)
        }

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("Kar Marjı")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("%\(Int(project.karMarjiPercent))")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
          }
          Slider(value: $project.karMarjiPercent, in: 0...50, step: 1)
            .tint(AppTheme.gold)
        }
      }
    }
  }

  private var notesSection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        sectionHeader("Notlar", icon: "note.text")
        TextEditor(text: $project.notes)
          .frame(minHeight: 100)
          .padding(8)
          .background(Color.white.opacity(0.55))
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
          .scrollContentBackground(.hidden)
      }
    }
  }

  private var calculationHistorySection: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        sectionHeader("Hesaplama Geçmişi", icon: "clock.arrow.circlepath")

        if project.savedCalculations.isEmpty {
          Text("Henüz hesaplama yapılmadı.")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
        } else {
          ForEach(project.savedCalculations.sorted(by: { $0.date > $1.date })) { calc in
            GlassInsetTile {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(calc.date, style: .date)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                  Text(MoneyFormatter.formatTRY(calc.grandTotalTry))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.navy)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                  Text("m² maliyet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                  Text(MoneyFormatter.formatTRY(calc.costPerM2Try))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                }
              }
            }
          }
        }
      }
    }
  }

  private var deleteSection: some View {
    Button(role: .destructive) {
      showDeleteConfirm = true
    } label: {
      HStack {
        Image(systemName: "trash.fill")
        Text("Projeyi Sil")
      }
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
    }
    .buttonStyle(.bordered)
    .tint(.red)
  }

  // MARK: - Helpers

  private func sectionHeader(_ title: String, icon: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundStyle(AppTheme.gold)
      Text(title)
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
    }
  }

  private func saveAndDismiss() {
    store.updateProject(project)
    dismiss()
  }
}

// MARK: - Supporting Views

private struct LabeledField<Content: View>: View {
  let label: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(AppTheme.textSecondary)
      content
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
    }
  }
}

private struct CustomPriceRow: View {
  let label: String
  let key: String
  @Binding var customPrices: [String: Double]

  private var isEnabled: Bool { customPrices[key] != nil }
  private var value: Double { customPrices[key] ?? 0 }

  var body: some View {
    HStack(spacing: 10) {
      Toggle(isOn: Binding(
        get: { isEnabled },
        set: { newVal in
          if newVal {
            customPrices[key] = 0
          } else {
            customPrices.removeValue(forKey: key)
          }
        }
      )) {
        Text(label)
          .font(.subheadline)
          .foregroundStyle(AppTheme.textPrimary)
      }
      .toggleStyle(SwitchToggleStyle(tint: AppTheme.gold))

      if isEnabled {
        TextField("₺", value: Binding(
          get: { value },
          set: { customPrices[key] = $0 }
        ), format: .number)
        .textFieldStyle(.plain)
        .keyboardType(.decimalPad)
        .frame(width: 100)
        .padding(8)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
      }
    }
  }
}
