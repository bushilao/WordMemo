import Foundation

/// 自评档位
enum ReviewGrade: CaseIterable {
    case forgot  // 忘记：降回第 1 级，当轮末尾重考
    case vague   // 模糊：等级不变，明天再复习
    case known   // 认识：升一级，按阶梯排期
}

/// 简化 SM-2：固定阶梯间隔 1→2→4→7→15→30 天，纯函数便于测试
enum ReviewScheduler {
    static let intervals: [TimeInterval] = [1, 2, 4, 7, 15, 30].map { $0 * 86_400 }

    /// 应用评分，返回是否需要当轮重考
    @discardableResult
    static func apply(_ grade: ReviewGrade, to word: WordItem, now: Date = .now) -> Bool {
        switch grade {
        case .forgot:
            word.level = 0
            word.dueDate = now
        case .vague:
            word.dueDate = now.addingTimeInterval(intervals[0])
        case .known:
            word.level = min(word.level + 1, intervals.count - 1)
            word.dueDate = now.addingTimeInterval(intervals[word.level])
        }
        word.introduced = true
        word.lastReviewedAt = now
        return grade == .forgot
    }

    static func nextIntervalDescription(for word: WordItem) -> String {
        let days = Int(intervals[word.level] / 86_400)
        return "\(days) 天后"
    }
}
