import SwiftUI
import SwiftData

/// 学习会话：闪卡 + 三档自评（忘记/模糊/认识）
/// 交互：左右滑动仅切换单词（原生分页），评分只通过底部按钮
struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SpeechService.self) private var speech
    @Environment(DataRevision.self) private var dataRevision

    @State private var deck: [WordItem]
    @State private var currentIndex = 0
    @State private var finished = false
    @State private var reviewedCount = 0

    init(deck: [WordItem]) {
        _deck = State(initialValue: deck)
    }

    private var current: WordItem? {
        deck.indices.contains(currentIndex) ? deck[currentIndex] : nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if finished {
                    summaryView
                } else {
                    sessionContent
                }
            }
            .navigationTitle("学习中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("结束") { dismiss() }
                }
            }
            // 学习结束时统一通知各页面刷新数据（而不是每次评分都刷新）
            .onDisappear { dataRevision.bump() }
        }
    }

    // MARK: - 学习主界面

    private var sessionContent: some View {
        VStack(spacing: 20) {
            progressHeader

            // 原生分页：滑动仅切换单词，老设备也流畅
            TabView(selection: $currentIndex) {
                ForEach(Array(deck.enumerated()), id: \.offset) { index, word in
                    FlashCardView(word: word, speech: speech)
                        .padding(.horizontal)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 440)

            gradeButtons
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private var progressHeader: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(min(currentIndex, deck.count)), total: Double(deck.count))
                .tint(Color.accentColor)
            HStack {
                Text("进度 \(min(currentIndex + 1, deck.count))/\(deck.count)")
                Spacer()
                Text("滑动切换 · 点下方按钮评分")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - 评分按钮（对标墨墨：实心色块 + 下次复习提示）

    private var gradeButtons: some View {
        HStack(spacing: 10) {
            gradeButton(.forgot, title: "忘记", effect: "当轮重考", color: Color(red: 0.91, green: 0.33, blue: 0.31))
            gradeButton(.vague, title: "模糊", effect: "1 天后", color: Color(red: 0.95, green: 0.61, blue: 0.21))
            gradeButton(.known, title: "认识", effect: knownEffectText, color: Color(red: 0.25, green: 0.70, blue: 0.45))
        }
    }

    /// 「认识」后下次复习的间隔（按当前阶梯等级）
    private var knownEffectText: String {
        guard let word = current else { return "" }
        let nextLevel = min(word.level + 1, ReviewScheduler.intervals.count - 1)
        let days = Int(ReviewScheduler.intervals[nextLevel] / 86_400)
        return "\(days) 天后"
    }

    private func gradeButton(_ grade: ReviewGrade, title: String, effect: String, color: Color) -> some View {
        Button {
            answer(grade)
        } label: {
            VStack(spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(effect)
                    .font(.caption2)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(color, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: color.opacity(0.35), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 结算页

    private var summaryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("本轮完成！")
                .font(.title.bold())
            Text("共复习 \(reviewedCount) 词次")
                .foregroundStyle(.secondary)
            Button("返回") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 逻辑

    private func answer(_ grade: ReviewGrade) {
        guard let word = current else { return }
        let requeue = ReviewScheduler.apply(grade, to: word)
        logReview()
        reviewedCount += 1

        if requeue {
            deck.append(word) // 忘记的词当轮末尾重考
        }

        withAnimation {
            if currentIndex + 1 >= deck.count {
                finished = true
            } else {
                currentIndex += 1
            }
        }
    }

    private func logReview() {
        let today = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<StudyDayLog> { $0.day == today }
        if let log = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first {
            log.reviewedCount += 1
        } else {
            modelContext.insert(StudyDayLog(day: today, reviewedCount: 1))
        }
    }
}

/// 闪卡：翻面状态为卡片私有，滑动浏览互不影响
private struct FlashCardView: View {
    let word: WordItem
    let speech: SpeechService

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Button {
                    speech.speak(word.english)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.1), in: Circle())
                }
            }

            Spacer()

            Text(word.english)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if !word.phonetic.isEmpty {
                Text(word.phonetic)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if revealed {
                Divider().padding(.horizontal, 48)
                Text(word.chinese)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                if !word.example.isEmpty {
                    Text(word.example)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                Text("点击卡片查看释义")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) { revealed.toggle() }
        }
    }
}
