import SwiftUI
import SwiftData
import UIKit

struct FocusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.focusMinutes) private var focusMinutes = 25

    private enum Phase {
        case idle
        case running(end: Date)
        case paused(remaining: TimeInterval)
        case finished
    }

    @State private var phase: Phase = .idle
    @State private var minutes = 25
    @State private var now = Date()
    @State private var recordAsStudy = true
    @State private var recordedMinutes = 0
    @State private var completionCount = 0

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var total: TimeInterval { Double(minutes * 60) }

    private var remaining: TimeInterval {
        switch phase {
        case .idle: total
        case .running(let end): max(end.timeIntervalSince(now), 0)
        case .paused(let remaining): remaining
        case .finished: 0
        }
    }

    private var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    private var isIdle: Bool {
        if case .idle = phase { return true }
        return false
    }

    private var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    private var statusText: String {
        switch phase {
        case .idle: "準備OK"
        case .running: "集中中..."
        case .paused: "一時停止中"
        case .finished: "おつかれさまでした！"
        }
    }

    var body: some View {
        ZStack {
            MountainArtView(showClimber: false)
                .ignoresSafeArea()
                .opacity(0.55)
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 28) {
                topBar
                Spacer()
                timerRing
                if isIdle { minuteAdjuster }
                if isFinished {
                    Text(recordedMinutes > 0 ? "勉強時間に\(recordedMinutes)分を記録しました" : "記録はしませんでした")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                controls
            }
            .padding(24)
        }
        .onAppear { minutes = focusMinutes }
        .onReceive(ticker) { date in
            now = date
            if case .running(let end) = phase, end <= date {
                complete()
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            NotificationManager.cancelFocusEnd()
        }
        .sensoryFeedback(.success, trigger: completionCount)
    }

    private var topBar: some View {
        ZStack {
            Text("集中モード")
                .font(.headline)
            HStack {
                Button {
                    if !isIdle && !isFinished { recordElapsed() }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
        }
        .foregroundStyle(.white)
    }

    private var timerRing: some View {
        let progress = total > 0 ? remaining / total : 0
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .offset(y: -130)
                .rotationEffect(.degrees(360 * progress))
                .animation(.linear(duration: 0.5), value: progress)
            VStack(spacing: 8) {
                Text(clockText(remaining))
                    .font(.system(size: 58, weight: .regular, design: .rounded).monospacedDigit())
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(width: 260, height: 260)
    }

    private var minuteAdjuster: some View {
        VStack(spacing: 14) {
            HStack(spacing: 24) {
                adjustButton("minus") { minutes = max(5, minutes - 5) }
                Text("\(minutes)分")
                    .font(Theme.number(20))
                    .frame(width: 80)
                adjustButton("plus") { minutes = min(120, minutes + 5) }
            }
            Toggle("勉強時間として記録", isOn: $recordAsStudy)
                .font(.footnote)
                .frame(maxWidth: 240)
                .tint(.gray)
        }
    }

    private func adjustButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.elevated))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var controls: some View {
        if isFinished {
            VStack(spacing: 12) {
                Button("もう一度") { reset() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("閉じる") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        } else {
            VStack(spacing: 18) {
                Button(action: toggleRunning) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .frame(width: 76, height: 76)
                        .background(Circle().fill(Color.white))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRunning ? "一時停止" : "開始")

                Button("終了") {
                    recordElapsed()
                    phase = .finished
                    stopSideEffects()
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 10)
                .background(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                .opacity(isIdle ? 0 : 1)
                .disabled(isIdle)
            }
        }
    }

    // MARK: - Actions

    private func toggleRunning() {
        switch phase {
        case .idle:
            start(duration: total)
        case .paused(let remaining):
            start(duration: remaining)
        case .running(let end):
            phase = .paused(remaining: max(end.timeIntervalSinceNow, 0))
            stopSideEffects()
        case .finished:
            break
        }
    }

    private func start(duration: TimeInterval) {
        let end = Date().addingTimeInterval(duration)
        now = Date()
        phase = .running(end: end)
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationManager.scheduleFocusEnd(at: end)
    }

    private func complete() {
        phase = .paused(remaining: 0)
        recordElapsed()
        phase = .finished
        stopSideEffects()
        completionCount += 1
    }

    private func reset() {
        phase = .idle
        recordedMinutes = 0
    }

    private func stopSideEffects() {
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationManager.cancelFocusEnd()
    }

    /// 経過時間を勉強時間として記録（1分未満は記録しない）
    private func recordElapsed() {
        let elapsedMinutes = Int((total - remaining) / 60)
        guard recordAsStudy, elapsedMinutes >= 1, recordedMinutes == 0 else { return }
        context.insert(LogEntry(kind: .study, value: Double(elapsedMinutes) / 60, note: "集中モード"))
        recordedMinutes = elapsedMinutes
    }

    private func clockText(_ seconds: TimeInterval) -> String {
        let value = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
