import SwiftUI
import PhotosUI

struct DiaryView: View {
  @ObservedObject private var store = ProjectStore.shared
  @State private var showingAddSheet = false

  private var project: SantiyeProject? { store.activeProject }

  private var entries: [DiaryEntry] {
    (project?.diaryEntries ?? []).sorted { $0.date > $1.date }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        if let _ = project {
          if entries.isEmpty {
            emptyState
          } else {
            ScrollView {
              LazyVStack(spacing: 14) {
                ForEach(entries) { entry in
                  DiaryEntryCard(entry: entry) {
                    deleteEntry(id: entry.id)
                  }
                }
              }
              .padding(.horizontal)
              .padding(.top, 8)
              .padding(.bottom, 28)
            }
            .dismissKeyboardOnTap()
          }
        } else {
          noProjectView
        }
      }
      .navigationTitle("Şantiye Günlüğü")
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
        AddDiaryEntrySheet()
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed.fill")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))
      Text("Henüz günlük girişi yok")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("Şantiye fotoğrafları ve notlar ekleyin")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }

  private var noProjectView: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.gold.opacity(0.6))
      Text("Aktif proje yok")
        .font(.title3.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary)
      Text("Günlük için bir proje seçin")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }

  private func deleteEntry(id: UUID) {
    guard var proj = store.activeProject else { return }
    proj.diaryEntries.removeAll { $0.id == id }
    store.activeProject = proj
  }
}

// MARK: - Entry Card

private struct DiaryEntryCard: View {
  let entry: DiaryEntry
  let onDelete: () -> Void

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.date, style: .date)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(AppTheme.textPrimary)
            Text(entry.date, style: .time)
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
          }
          Spacer()

          if entry.workerCount > 0 {
            Label("\(entry.workerCount) işçi", systemImage: "person.fill")
              .font(.caption.weight(.medium))
              .foregroundStyle(AppTheme.navy)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(AppTheme.gold.opacity(0.15))
              .clipShape(Capsule())
          }

          Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
              .font(.caption)
          }
        }

        if !entry.weather.isEmpty {
          Label(entry.weather, systemImage: "cloud.sun.fill")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }

        if !entry.note.isEmpty {
          Text(entry.note)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
        }

        if !entry.photoFileNames.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(entry.photoFileNames, id: \.self) { fileName in
                if let image = loadImage(named: fileName) {
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
                } else {
                  RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                    .fill(AppTheme.navy.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .overlay {
                      Image(systemName: "photo")
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
              }
            }
          }
        }
      }
    }
  }

  private func loadImage(named fileName: String) -> UIImage? {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    guard let url = dir?.appendingPathComponent("diary_photos/\(fileName)") else { return nil }
    return UIImage(contentsOfFile: url.path)
  }
}

// MARK: - Add Entry Sheet

private struct AddDiaryEntrySheet: View {
  @ObservedObject private var store = ProjectStore.shared
  @Environment(\.dismiss) private var dismiss

  @State private var note = ""
  @State private var weather = ""
  @State private var workerCount = 0
  @State private var selectedPhotos: [PhotosPickerItem] = []
  @State private var loadedImages: [UIImage] = []

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            GlassCard {
              VStack(alignment: .leading, spacing: 14) {
                Text("Not")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                TextEditor(text: $note)
                  .frame(minHeight: 80)
                  .padding(8)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
                  .scrollContentBackground(.hidden)

                Text("Hava Durumu")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                TextField("Örn: Güneşli, 28°C", text: $weather)
                  .textFieldStyle(.plain)
                  .padding(12)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))

                Text("İşçi Sayısı")
                  .font(.subheadline.weight(.medium))
                  .foregroundStyle(AppTheme.textSecondary)
                Stepper("\(workerCount) kişi", value: $workerCount, in: 0...500)
              }
            }

            GlassCard {
              VStack(alignment: .leading, spacing: 12) {
                Text("Fotoğraflar")
                  .font(.headline)
                  .foregroundStyle(AppTheme.textPrimary)

                PhotosPicker(
                  selection: $selectedPhotos,
                  maxSelectionCount: 5,
                  matching: .images
                ) {
                  HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Fotoğraf Seç")
                  }
                  .font(.subheadline.weight(.medium))
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.white.opacity(0.55))
                  .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
                }
                .onChange(of: selectedPhotos) { items in
                  loadImages(from: items)
                }

                if !loadedImages.isEmpty {
                  ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                      ForEach(loadedImages.indices, id: \.self) { idx in
                        Image(uiImage: loadedImages[idx])
                          .resizable()
                          .scaledToFill()
                          .frame(width: 80, height: 80)
                          .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous))
                      }
                    }
                  }
                }
              }
            }

            Button {
              saveEntry()
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
      .navigationTitle("Yeni Günlük Girişi")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("İptal") { dismiss() }
            .foregroundStyle(AppTheme.navy)
        }
      }
    }
  }

  private func loadImages(from items: [PhotosPickerItem]) {
    loadedImages = []
    for item in items {
      item.loadTransferable(type: Data.self) { result in
        if case .success(let data?) = result, let img = UIImage(data: data) {
          DispatchQueue.main.async { loadedImages.append(img) }
        }
      }
    }
  }

  private func saveEntry() {
    guard var proj = store.activeProject else { return }
    var entry = DiaryEntry(note: note, weather: weather, workerCount: workerCount)

    let fileNames = savePhotos(loadedImages)
    entry.photoFileNames = fileNames

    proj.diaryEntries.append(entry)
    store.activeProject = proj
    dismiss()
  }

  private func savePhotos(_ images: [UIImage]) -> [String] {
    guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return []
    }
    let photosDir = dir.appendingPathComponent("diary_photos")
    try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

    var names: [String] = []
    for image in images {
      let name = UUID().uuidString + ".jpg"
      let url = photosDir.appendingPathComponent(name)
      if let data = image.jpegData(compressionQuality: 0.7) {
        try? data.write(to: url)
        names.append(name)
      }
    }
    return names
  }
}
