import Foundation
import SwiftData

/// 首次启动时把内置词书（Resources/WordBooks/*.json）导入 SwiftData
enum WordSeeder {
    private struct SeedWord: Decodable {
        let english: String
        let phonetic: String
        let chinese: String
        let example: String
    }

    static func seedIfNeeded(context: ModelContext) {
        for book in WordBookCatalog.all {
            seedBook(book, context: context)
        }
        try? context.save()
    }

    private static func seedBook(_ book: WordBook, context: ModelContext) {
        let bookID = book.id
        var descriptor = FetchDescriptor<WordItem>(predicate: #Predicate { $0.book == bookID })
        descriptor.fetchLimit = 1
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        guard let url = Bundle.main.url(forResource: book.resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seedWords = try? JSONDecoder().decode([SeedWord].self, from: data)
        else { return }

        for seed in seedWords {
            context.insert(WordItem(
                english: seed.english,
                phonetic: seed.phonetic,
                chinese: seed.chinese,
                example: seed.example,
                book: book.id
            ))
        }
    }
}
