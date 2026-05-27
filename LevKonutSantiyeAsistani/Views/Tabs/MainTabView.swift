import SwiftUI

struct MainTabView: View {
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      DashboardView()
        .tabItem {
          Label("Ana Sayfa", systemImage: "house.fill")
        }
        .tag(0)

      ProjectsView()
        .tabItem {
          Label("Projeler", systemImage: "folder.fill")
        }
        .tag(1)

      HakedisView()
        .tabItem {
          Label("Hakediş", systemImage: "chart.bar.doc.horizontal.fill")
        }
        .tag(2)

      PuantajView()
        .tabItem {
          Label("Puantaj", systemImage: "person.3.fill")
        }
        .tag(3)

      SettingsView()
        .tabItem {
          Label("Ayarlar", systemImage: "gearshape.fill")
        }
        .tag(4)
    }
    .tint(AppTheme.gold)
  }
}
