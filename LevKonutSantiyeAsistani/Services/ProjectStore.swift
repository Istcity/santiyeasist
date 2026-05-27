import Foundation
import Combine

@MainActor
final class ProjectStore: ObservableObject {
  static let shared = ProjectStore()

  @Published var projects: [SantiyeProject] = []
  @Published var activeProjectID: UUID?

  private let projectsKey = "santiye_projects"
  private let activeIDKey = "santiye_active_project_id"

  var activeProject: SantiyeProject? {
    get { projects.first { $0.id == activeProjectID } }
    set {
      guard let newValue, let idx = projects.firstIndex(where: { $0.id == newValue.id }) else { return }
      projects[idx] = newValue
      persist()
    }
  }

  private init() { load() }

  func load() {
    projects = LocalCacheService.shared.load([SantiyeProject].self, forKey: projectsKey) ?? []
    if let idString = UserDefaults.standard.string(forKey: activeIDKey) {
      activeProjectID = UUID(uuidString: idString)
    }
    if activeProjectID == nil, let first = projects.first {
      activeProjectID = first.id
    }
  }

  func addProject(_ project: SantiyeProject) {
    projects.append(project)
    if activeProjectID == nil { activeProjectID = project.id }
    persist()
  }

  func deleteProject(id: UUID) {
    projects.removeAll { $0.id == id }
    if activeProjectID == id {
      activeProjectID = projects.first?.id
    }
    persist()
  }

  func setActive(id: UUID) {
    guard projects.contains(where: { $0.id == id }) else { return }
    activeProjectID = id
    UserDefaults.standard.set(id.uuidString, forKey: activeIDKey)
  }

  func updateProject(_ project: SantiyeProject) {
    guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
    var updated = project
    updated.updatedAt = Date()
    projects[idx] = updated
    persist()
  }

  private func persist() {
    LocalCacheService.shared.save(projects, forKey: projectsKey)
    if let id = activeProjectID {
      UserDefaults.standard.set(id.uuidString, forKey: activeIDKey)
    }
  }
}
