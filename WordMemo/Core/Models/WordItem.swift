import Foundation
import SwiftData

/// 单词及其学习进度（简化 SM-2 阶梯调度状态）
@Model
final class WordItem {
    var english: String
    var phonetic: String
    var chinese: String
    var example: String
    /// 所属词书 id（WordBook.id）
    var book: String

    /// 记忆阶梯等级（0...ReviewScheduler.intervals.count-1）
    var level: Int
    /// 下次到期复习时间
    var dueDate: Date
    /// 是否已学过（false = 新词，未进入排期）
    var introduced: Bool
    var lastReviewedAt: Date?

    init(english: String, phonetic: String, chinese: String, example: String, book: String) {
        self.english = english
        self.phonetic = phonetic
        self.chinese = chinese
        self.example = example
        self.book = book
        self.level = 0
        self.dueDate = .now
        self.introduced = false
        self.lastReviewedAt = nil
    }
}

extension WordItem {
    /// 已掌握：阶梯爬到倒数第二级以上
    var isMastered: Bool {
        level >= ReviewScheduler.intervals.count - 2
    }
}
