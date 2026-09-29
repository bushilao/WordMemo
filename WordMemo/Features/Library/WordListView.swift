import SwiftUI
import SwiftData

/// 「词书」页：当前词书的单词列表、搜索、掌握状态一览，可切换词书
struct WordListView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(\.modelContext) private var modelContext
    @Environment(DataRevision.self) private var dataRevision
    @AppStorage("activeBookID") private var activeBookID = WordBookCatalog.defaultBookID

    @State private var words: [WordItem] = []
    @State private var searchText = ""
    @State private var loadedRevision = -1
    @State private var loadedBookID = ""
    @State private var showingBookManager = false
    @AppStorage(WordBookCatalog.deletedKey) private var deletedRaw = ""

    private var filtered: [WordItem] {
        if searchText.isEmpty { return words }
        return words.filter {
            $0.english.localizedCaseInsensitiveContains(searchText) ||
            $0.chinese.contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { word in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(word.english).font(.headline)
                            Text(word.phonetic)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(word.chinese)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusBadge(for: word)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    speech.speak(word.english)
                }
            }
            .navigationTitle(WordBookCatalog.book(id: activeBookID).title)
            .searchable(text: $searchText, prompt: "搜索单词或释义")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(WordBookCatalog.available) { book in
                            Button {
                                activeBookID = book.id
                            } label: {
                                if book.id == activeBookID {
                                    Label(book.title, systemImage: "checkmark")
                                } else {
                                    Text(book.title)
                                }
                            }
                        }
                        Divider()
                        Button {
                            showingBookManager = true
                        } label: {
                            Label("管理词书", systemImage: "gearshape")
                        }
                    } label: {
                        Label("切换词书", systemImage: "books.vertical")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Text("\(words.filter(\.isMastered).count)/\(words.count) 已掌握")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .task { reloadIfNeeded() }
            .onAppear { reloadIfNeeded() }
            .sheet(isPresented: $showingBookManager) {
                BookManagerView()
            }
            // 数据/词书变化时只标记失效，页面可见时才真正查询
            .onChange(of: activeBookID) { loadedBookID = "" }
            .onChange(of: dataRevision.revision) { loadedRevision = -1 }
            .onChange(of: deletedRaw) { loadedBookID = "" }
        }
    }

    /// 仅当数据版本或词书变化时才查询（避免切 Tab 时空查数据库）
    private func reloadIfNeeded() {
        guard loadedRevision != dataRevision.revision || loadedBookID != activeBookID else { return }
        let descriptor = FetchDescriptor<WordItem>(
            predicate: #Predicate { $0.book == activeBookID },
            sortBy: [SortDescriptor(\.english)]
        )
        words = (try? modelContext.fetch(descriptor)) ?? []
        loadedRevision = dataRevision.revision
        loadedBookID = activeBookID
    }

    @ViewBuilder
    private func statusBadge(for word: WordItem) -> some View {
        if !word.introduced {
            Text("新词")
                .font(.caption)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.blue.opacity(0.15), in: Capsule())
                .foregroundStyle(.blue)
        } else if word.isMastered {
            Label("已掌握", systemImage: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            Text("L\(word.level) · \(word.dueDate <= .now ? "待复习" : ReviewScheduler.nextIntervalDescription(for: word))")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    WordListView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
