import Foundation

/// 数据版本号：学习评分后递增，各页面据此决定是否需要重新查询，避免切 Tab 时空查数据库
@Observable
final class DataRevision {
    private(set) var revision = 0

    func bump() {
        revision += 1
    }
}
