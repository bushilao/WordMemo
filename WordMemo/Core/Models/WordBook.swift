import Foundation

/// 词书元数据（对应 Resources/WordBooks/<id>.json）
struct WordBook: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String

    var resourceName: String { id }
}

enum WordBookCatalog {
    static let defaultBookID = "gaokao"

    static let all: [WordBook] = [
        WordBook(id: "gaokao", title: "高考必备词汇", subtitle: "约 3600 词 · 高考大纲"),
        WordBook(id: "basic", title: "基础入门 30 词", subtitle: "30 词 · 体验用"),
    ]

    static func book(id: String) -> WordBook {
        all.first { $0.id == id } ?? all[0]
    }
}
