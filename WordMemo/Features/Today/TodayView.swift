import SwiftUI
import SwiftData

/// 学习会话配置（用于 fullScreenCover(item:) 传参）
struct StudySessionConfig: Identifiable {
    let id = UUID()
    let words: [WordItem]
}

/// 「今日」页：今日待复习 + 新词配额入口（复习优先，新学补齐，对标墨墨）
struct TodayView: View {
    @AppStorage("dailyNewLimit") private var dailyNewLimit = 20
    @AppStorage("activeBookID") private var activeBookID = WordBookCatalog.defaultBookID
    @Environment(\.modelContext) private var modelContext
    @Environment(DataRevision.self) private var dataRevision

    @State private var allWords: [WordItem] = []
    @State private var session: StudySessionConfig?
    @State private var loadedRevision = -1
    @State private var loadedBookID = ""

    private var words: [WordItem] {
        allWords.filter { $0.book == activeBookID }
    }

    private var activeBook: WordBook {
        WordBookCatalog.book(id: activeBookID)
    }

    private var dueReviews: [WordItem] {
        words.filter { $0.introduced && $0.dueDate <= .now }
    }

    /// 全部剩余新词
    private var newWords: [WordItem] {
        words.filter { !$0.introduced }
    }

    /// 今日计划内的新词（每日配额）
    private var plannedNewWords: [WordItem] {
        Array(newWords.prefix(dailyNewLimit))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text("词忆")
                        .font(.largeTitle.bold())
                    Text(Date.now.formatted(.dateTime.month().day().weekday().locale(Locale(identifier: "zh_CN"))))
                        .foregroundStyle(.secondary)
                    Text(activeBook.title)
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }

                HStack(spacing: 16) {
                    statCard(title: "待复习", count: dueReviews.count, color: .orange)
                    statCard(title: "今日新词", count: plannedNewWords.count, color: .blue)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    session = StudySessionConfig(words: dueReviews + plannedNewWords)
                } label: {
                    Text(dueReviews.isEmpty && plannedNewWords.isEmpty ? "今日任务已完成" : "开始今日任务")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(dueReviews.isEmpty && plannedNewWords.isEmpty)
                .padding(.horizontal, 40)

                // 自由模式：不受每日配额限制，愿意背多少背多少
                if !newWords.isEmpty {
                    Button {
                        session = StudySessionConfig(words: dueReviews + newWords)
                    } label: {
                        Text("自由背词（剩余 \(newWords.count) 个新词，不限量）")
                            .font(.callout)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .navigationTitle("今日学习")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $session, onDismiss: reloadIfNeeded) { config in
                StudySessionView(deck: config.words)
            }
            .task {
                reloadIfNeeded()
                // UI 演示钩子：带 -ui-study-demo 启动参数时自动打开学习页
                if session == nil,
                   ProcessInfo.processInfo.arguments.contains("-ui-study-demo") {
                    session = StudySessionConfig(words: Array(words.prefix(5)))
                }
            }
            .onChange(of: activeBookID) { reloadIfNeeded() }
            .onChange(of: dataRevision.revision) { reloadIfNeeded() }
        }
    }

    /// 仅当数据版本或词书变化时才查询（避免切 Tab 时空查数据库）
    private func reloadIfNeeded() {
        guard loadedRevision != dataRevision.revision || loadedBookID != activeBookID else { return }
        let descriptor = FetchDescriptor<WordItem>(sortBy: [SortDescriptor(\.dueDate)])
        allWords = (try? modelContext.fetch(descriptor)) ?? []
        loadedRevision = dataRevision.revision
        loadedBookID = activeBookID
    }

    private func statCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
