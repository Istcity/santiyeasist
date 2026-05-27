import SwiftUI

struct ProjectsView: View {
  @ObservedObject private var store = ProjectStore.shared
  @ObservedObject private var rewardedService = RewardedAdService.shared
  @State private var showingAddSheet = false
  @State private var showingAdAlert = false
  @State private var selectedProject: SantiyeProject?
  @State private var projectToDelete: SantiyeProject?
  @State private var showDeleteAlert = false

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
          LazyVStack(spacing: 14) {
            ForEach(store.projects) { project in
              SwipeableProjectCard(
                project: project,
                isActive: project.id == store.activeProjectID,
                onTap: { store.setActive(id: project.id) },
                onEdit: { selectedProject = project },
                onDelete: {
                  projectToDelete = project
                  showDeleteAlert = true
                }
              )
            }
          }
          .padding(.horizontal)
          .padding(.top, 8)
          .padding(.bottom, 28)
        }
        .dismissKeyboardOnTap()
      }
      .navigationTitle("Projeler")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            handleAddProject()
          } label: {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundStyle(AppTheme.gold)
          }
        }
      }
      .sheet(isPresented: $showingAddSheet) {
        AddProjectSheet()
      }
      .sheet(item: $selectedProject) { project in
        NavigationStack {
          ProjectDetailView(project: project)
        }
      }
      .alert("Reklam İzle", isPresented: $showingAdAlert) {
        Button("Reklam İzle") {
          rewardedService.requestFeatureUnlock(.unlimitedProjects) { success in
            if success { showingAddSheet = true }
          }
        }
        Button("İptal", role: .cancel) {}
      } message: {
        Text("2'den fazla proje eklemek için kısa bir reklam izleyin. \(PremiumFeature.unlimitedProjects.sessionDurationMinutes) dakika aktif kalır.")
      }
      .alert("Projeyi Sil", isPresented: $showDeleteAlert) {
        Button("Sil", role: .destructive) {
          if let p = projectToDelete {
            store.deleteProject(id: p.id)
            projectToDelete = nil
          }
        }
        Button("İptal", role: .cancel) {
          projectToDelete = nil
        }
      } message: {
        Text("'\(projectToDelete?.name ?? "")' projesini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
      }
      .overlay {
        if store.projects.isEmpty {
          emptyState
        }
      }
    }
  }

  private func handleAddProject() {
    if store.projects.count >= 2 && !rewardedService.isFeatureUnlocked(.unlimitedProjects) {
      showingAdAlert = true
    } else {
      showingAddSheet = true
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "building.2.crop.circle")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))
      Text("Henüz proje yok")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("Yeni bir proje ekleyerek başlayın")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }
}

// MARK: - Swipeable Card Wrapper

private struct SwipeableProjectCard: View {
  let project: SantiyeProject
  let isActive: Bool
  let onTap: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  @State private var offset: CGFloat = 0
  @State private var showingDeleteBG = false

  var body: some View {
    ZStack(alignment: .trailing) {
      if showingDeleteBG {
        HStack {
          Spacer()
          VStack(spacing: 4) {
            Image(systemName: "trash.fill")
              .font(.title2)
            Text("Sil")
              .font(.caption.weight(.semibold))
          }
          .foregroundStyle(.white)
          .frame(width: 80)
        }
        .frame(maxHeight: .infinity)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
      }

      ProjectCardView(project: project, isActive: isActive)
        .offset(x: offset)
        .gesture(
          DragGesture()
            .onChanged { value in
              let dx = value.translation.width
              if dx < 0 {
                offset = dx
                showingDeleteBG = dx < -30
              }
            }
            .onEnded { value in
              if value.translation.width < -100 {
                withAnimation(.spring(response: 0.3)) { offset = 0 }
                showingDeleteBG = false
                onDelete()
              } else {
                withAnimation(.spring(response: 0.3)) { offset = 0 }
                showingDeleteBG = false
              }
            }
        )
        .onTapGesture { onTap() }
        .onLongPressGesture { onEdit() }
    }
  }
}

// MARK: - Project Card

private struct ProjectCardView: View {
  let project: SantiyeProject
  let isActive: Bool

  var body: some View {
    GlassCard {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .fill(AppTheme.gold.opacity(0.15))
            .frame(width: 48, height: 48)
          Image(systemName: iconForType(project.buildingType))
            .font(.title3)
            .foregroundStyle(AppTheme.gold)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(project.name)
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)

          HStack(spacing: 8) {
            Label(project.buildingType.rawValue, systemImage: "tag.fill")
            Text("•")
            Text(project.createdAt, style: .date)
          }
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)

          if let lastCalc = project.savedCalculations.last {
            Text(MoneyFormatter.formatTRY(lastCalc.grandTotalTry))
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.navy)
          }
        }

        Spacer()

        if isActive {
          Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundStyle(AppTheme.gold)
        }
      }
    }
    .overlay {
      if isActive {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
          .stroke(AppTheme.gold, lineWidth: 2)
      }
    }
  }

  private func iconForType(_ type: BuildingType) -> String {
    switch type {
    case .konut: return "house.fill"
    case .ticari: return "building.2.fill"
    case .endustriyel: return "gear.circle.fill"
    case .villa: return "house.lodge.fill"
    }
  }
}

// MARK: - Add Project Sheet

private struct AddProjectSheet: View {
  @ObservedObject private var store = ProjectStore.shared
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var buildingType: BuildingType = .konut

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            GlassCard {
              VStack(alignment: .leading, spacing: 14) {
                Text("Proje Adı")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                TextField("Proje adı girin", text: $name)
                  .textFieldStyle(.plain)
                  .padding(12)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))

                Text("Yapı Türü")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                Picker("Yapı Türü", selection: $buildingType) {
                  ForEach(BuildingType.allCases) { type in
                    Text(type.rawValue).tag(type)
                  }
                }
                .pickerStyle(.segmented)
              }
            }

            Button {
              let project = SantiyeProject(
                name: name.isEmpty ? "Yeni Proje" : name,
                buildingType: buildingType
              )
              store.addProject(project)
              dismiss()
            } label: {
              Text("Proje Oluştur")
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
      .navigationTitle("Yeni Proje")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("İptal") { dismiss() }
            .foregroundStyle(AppTheme.navy)
        }
      }
    }
  }
}
