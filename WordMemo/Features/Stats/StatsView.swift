import SwiftUI
import SwiftData

/// 「统计」页：学习总量、掌握进度、连续打卡
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DataRevision.self) private var dataRevision
    @AppStorage("activeBookID") private var activeBookID = WordBookCatalog.defaultBookID

    @State private var words: [WordItem] = []
    @State private var logs: [StudyDayLog] = []
    @State private var loadedRevision = -1
    @State private var loadedBookID = ""

    private var masteredCount: Int { words.filter(\.isMastered).count }
    private var learningCount: Int { words.filter { $0.introduced && !$0.isMastered }.count }
    private var newCount: Int { words.filter { !$0.introduced }.count }
    private var totalReviews: Int { logs.reduce(0) { $0 + $1.reviewedCount } }
    private var todayReviews: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return logs.first { $0.day == today }?.reviewedCount ?? 0
    }

    private var streak: Int {
        let days = Set(logs.filter { $0.reviewedCount > 0 }.map(\.day))
        var cursor = Calendar.current.startOfDay(for: .now)
        if !days.contains(cursor) {
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("今日") {
                    statRow("今日已复习", "\(todayReviews) 词次")
                    statRow("连续打卡", "\(streak) 天")
                }

                Section("掌握进度") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: words.isEmpty ? 0 : Double(masteredCount) / Double(words.count))
                            .tint(.green)
                        Text("已掌握 \(masteredCount) / \(words.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    statRow("学习中", "\(learningCount) 词")
                    statRow("未学习", "\(newCount) 词")
                }

                Section("累计") {
                    statRow("累计复习", "\(totalReviews) 词次")
                    statRow("学习天数", "\(logs.filter { $0.reviewedCount > 0 }.count) 天")
                }
            }
            .navigationTitle("统计")
            .task { reloadIfNeeded() }
            .onAppear { reloadIfNeeded() }
            // 数据/词书变化时只标记失效，页面可见时才真正查询
            .onChange(of: activeBookID) { loadedBookID = "" }
            .onChange(of: dataRevision.revision) { loadedRevision = -1 }
        }
    }

    /// 仅当数据版本或词书变化时才查询（避免切 Tab 时空查数据库）
    private func reloadIfNeeded() {
        guard loadedRevision != dataRevision.revision || loadedBookID != activeBookID else { return }
        let wordDescriptor = FetchDescriptor<WordItem>(predicate: #Predicate { $0.book == activeBookID })
        words = (try? modelContext.fetch(wordDescriptor)) ?? []
        let logDescriptor = FetchDescriptor<StudyDayLog>(sortBy: [SortDescriptor(\.day, order: .reverse)])
        logs = (try? modelContext.fetch(logDescriptor)) ?? []
        loadedRevision = dataRevision.revision
        loadedBookID = activeBookID
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
