import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var speech = SpeechService()
    @State private var dataRevision = DataRevision()

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "book.fill") }
            WordListView()
                .tabItem { Label("词书", systemImage: "list.bullet.rectangle") }
            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
        .environment(speech)
        .environment(dataRevision)
        .task {
            WordSeeder.seedIfNeeded(context: modelContext)
            dataRevision.bump()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
