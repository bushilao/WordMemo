import SwiftUI
import SwiftData

/// 「设置」页：每日新词量、重置学习数据
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DataRevision.self) private var dataRevision
    @AppStorage("dailyNewLimit") private var dailyNewLimit = 20

    @State private var showingResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("每日新词目标：\(dailyNewLimit) 个", value: $dailyNewLimit, in: 5...100, step: 5)
                } header: {
                    Text("学习计划")
                } footer: {
                    Text("目标是每日建议量，背完后仍可通过「自由背词」继续学习。")
                }

                Section("数据") {
                    Button("重置学习进度", role: .destructive) {
                        showingResetConfirm = true
                    }
                }

                Section("关于") {
                    LabeledContent("应用", value: "词忆 WordMemo")
                    LabeledContent("版本", value: "1.0")
                }
            }
            .navigationTitle("设置")
            .confirmationDialog("确定要重置所有学习进度吗？词库会保留，所有单词回到未学习状态。", isPresented: $showingResetConfirm, titleVisibility: .visible) {
                Button("重置", role: .destructive, action: resetProgress)
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func resetProgress() {
        if let words = try? modelContext.fetch(FetchDescriptor<WordItem>()) {
            for word in words {
                word.level = 0
                word.introduced = false
                word.dueDate = .now
                word.lastReviewedAt = nil
            }
        }
        if let logs = try? modelContext.fetch(FetchDescriptor<StudyDayLog>()) {
            for log in logs { modelContext.delete(log) }
        }
        dataRevision.bump()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WordItem.self, StudyDayLog.self], inMemory: true)
}
