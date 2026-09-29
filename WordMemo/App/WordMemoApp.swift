import SwiftUI
import SwiftData

@main
struct WordMemoApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [WordItem.self, StudyDayLog.self])
    }
}
