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
    static let deletedKey = "deletedBookIDs"

    static let all: [WordBook] = [
        WordBook(id: "junior", title: "初中英语词汇", subtitle: "2011 词 · 中考大纲"),
        WordBook(id: "senior", title: "高中英语词汇", subtitle: "2416 词 · 高中课标"),
        WordBook(id: "gaokao", title: "高考必备词汇", subtitle: "3665 词 · 高考大纲"),
        WordBook(id: "cet6", title: "六级词汇", subtitle: "1665 词 · CET-6"),
        WordBook(id: "kaoyan", title: "考研词汇", subtitle: "5493 词 · 考研大纲"),
        WordBook(id: "basic", title: "基础入门 30 词", subtitle: "30 词 · 体验用"),
    ]

    static var deletedIDs: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: deletedKey) ?? ""
            return Set(raw.split(separator: ",").map(String.init))
        }
        set {
            UserDefaults.standard.set(newValue.joined(separator: ","), forKey: deletedKey)
        }
    }

    /// 未被删除的词书
    static var available: [WordBook] {
        all.filter { !deletedIDs.contains($0.id) }
    }

    static func book(id: String) -> WordBook {
        available.first { $0.id == id } ?? available.first ?? all[0]
    }

    static func deleteBook(_ id: String) {
        var ids = deletedIDs
        ids.insert(id)
        deletedIDs = ids
    }

    static func restoreBook(_ id: String) {
        var ids = deletedIDs
        ids.remove(id)
        deletedIDs = ids
    }
}
