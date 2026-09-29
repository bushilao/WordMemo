import Foundation
import SwiftData

/// 每日学习记录（用于打卡/统计）
@Model
final class StudyDayLog {
    /// 当天零点（唯一）
    @Attribute(.unique) var day: Date
    var reviewedCount: Int

    init(day: Date, reviewedCount: Int = 0) {
        self.day = day
        self.reviewedCount = reviewedCount
    }
}
