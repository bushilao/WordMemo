import SwiftUI
import SwiftData

/// 词书管理：删除/恢复词书
struct BookManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(DataRevision.self) private var dataRevision
    @AppStorage("activeBookID") private var activeBookID = WordBookCatalog.defaultBookID
    @AppStorage(WordBookCatalog.deletedKey) private var deletedRaw = ""

    @State private var bookToDelete: WordBook?

    private var deletedIDs: Set<String> {
        Set(deletedRaw.split(separator: ",").map(String.init))
    }

    private var availableBooks: [WordBook] {
        WordBookCatalog.all.filter { !deletedIDs.contains($0.id) }
    }

    private var deletedBooks: [WordBook] {
        WordBookCatalog.all.filter { deletedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("我的词书") {
                    ForEach(availableBooks) { book in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                Text(book.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if book.id == activeBookID {
                                Text("使用中")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .onDelete { offsets in
                        if let index = offsets.first {
                            bookToDelete = availableBooks[index]
                        }
                    }
                }

                if !deletedBooks.isEmpty {
                    Section("已删除（可恢复）") {
                        ForEach(deletedBooks) { book in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .foregroundStyle(.secondary)
                                    Text(book.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Button("恢复") {
                                    WordBookCatalog.restoreBook(book.id)
                                    deletedRaw = WordBookCatalog.deletedIDs.joined(separator: ",")
                                    WordSeeder.seedIfNeeded(context: modelContext)
                                    dataRevision.bump()
                                }
                                .font(.callout)
                            }
                        }
                    }
                }
            }
            .navigationTitle("词书管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .confirmationDialog(
                "删除后将清除该词书的全部单词和学习进度，可随时恢复（进度不保留）。",
                isPresented: Binding(get: { bookToDelete != nil }, set: { if !$0 { bookToDelete = nil } }),
                titleVisibility: .visible
            ) {
                if let book = bookToDelete {
                    Button("删除「\(book.title)」", role: .destructive) { delete(book) }
                }
                Button("取消", role: .cancel) { bookToDelete = nil }
            }
        }
    }

    private func delete(_ book: WordBook) {
        // 批量删除该词书的全部单词
        let bookID = book.id
        try? modelContext.delete(model: WordItem.self, where: #Predicate { $0.book == bookID })
        WordBookCatalog.deleteBook(book.id)
        deletedRaw = WordBookCatalog.deletedIDs.joined(separator: ",")

        // 删掉的是当前使用的词书 → 自动切到剩余的第一本
        if activeBookID == book.id, let first = WordBookCatalog.available.first {
            activeBookID = first.id
        }
        dataRevision.bump()
        bookToDelete = nil
    }
}

#Preview {
    BookManagerView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
