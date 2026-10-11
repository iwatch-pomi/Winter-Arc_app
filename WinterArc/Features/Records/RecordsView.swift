import SwiftUI
import SwiftData
import Charts

struct RecordsView: View {
    @Query(sort: \LogEntry.date) private var logs: [LogEntry]
    @Query private var tasks: [TaskItem]
    @AppStorage(SettingsKey.targetWeight) private var targetWeight: Double = 0

    @State private var period: RecordPeriod = .week
    @State private var anchor = Date()
    @State private var addingKind: LogKind?

    private var interval: DateInterval { period.interval(containing: anchor) }
    private var previousInterval: DateInterval { period.interval(containing: period.shift(anchor, by: -1)) }
    private var isCurrentPeriod: Bool { interval.contains(Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    periodPicker
                    periodNavigator
                    studyCard
                    weightCard
                    taskCard
                    barCard(.exercise)
                    barCard(.book)
                    sleepCard
                    NavigationLink {
                        LogHistoryView()
                    } label: {
                        HStack {
                            Label("記録の履歴", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.tertiaryText)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .winterScreen()
            .navigationTitle("記録")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(LogKind.allCases) { kind in
                            Button {
                                addingKind = kind
                            } label: {
                                Label(kind.title, systemImage: kind.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(item: $addingKind) { kind in
                LogEntryEditorView(kind: kind)
            }
        }
    }

    // MARK: - Header

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(RecordPeriod.allCases) { item in
                Button {
                    withAnimation(.snappy) {
                        period = item
                        anchor = Date()
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(period == item ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(period == item ? Color.white : Color.clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
    }

    private var periodNavigator: some View {
        HStack {
            Button {
                anchor = period.shift(anchor, by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(period.title(for: interval))
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                anchor = period.shift(anchor, by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isCurrentPeriod)
            .opacity(isCurrentPeriod ? 0.3 : 1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
    }

    // MARK: - Cards

    private var studyCard: some View {
        let total = logs.total(.study, in: interval)
        let previous = logs.total(.study, in: previousInterval)
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle(.study)
            HStack(alignment: .firstTextBaseline) {
                StatValue(value: TimeText.number(total), suffix: "h", size: 34)
                Spacer()
                Text("\(period.comparisonLabel) \(TimeText.signed(total - previous))h")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            bars(.study)
        }
        .card()
    }

    private var weightCard: some View {
        let entries = logs.entries(.weight, in: interval)
        let latestOverall = logs.filter { $0.kind == .weight && $0.date < interval.end }.last
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle(.weight)
            if let first = entries.first, let last = entries.last {
                HStack(alignment: .firstTextBaseline) {
                    StatValue(value: TimeText.signed(last.value - first.value), suffix: "kg", size: 34)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("現在 \(TimeText.number(last.value))kg")
                        if targetWeight > 0 {
                            Text("目標まで \(TimeText.signed(targetWeight - last.value))kg")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                }
                weightChart(entries)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    if let latestOverall {
                        StatValue(value: TimeText.number(latestOverall.value), suffix: "kg", size: 34)
                        Spacer()
                        Text("この期間の記録なし")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        emptyText
                    }
                }
            }
        }
        .card()
    }

    private func weightChart(_ entries: [LogEntry]) -> some View {
        let values = entries.map(\.value)
        let low = (values.min() ?? 0) - 0.5
        let high = (values.max() ?? 0) + 0.5
        return Chart(entries) { entry in
            LineMark(x: .value("日付", entry.date), y: .value("体重", entry.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.white)
            PointMark(x: .value("日付", entry.date), y: .value("体重", entry.value))
                .foregroundStyle(Color.white)
                .symbolSize(24)
        }
        .chartYScale(domain: low...high)
        .chartXScale(domain: interval.start...interval.end)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 80)
    }

    private var taskCard: some View {
        let periodTasks = tasks.tasks(in: interval)
        let done = periodTasks.filter(\.isDone).count
        let rate = periodTasks.isEmpty ? 0 : Double(done) / Double(periodTasks.count)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("総タスク完了数", systemImage: "checkmark.square")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            HStack(alignment: .firstTextBaseline) {
                StatValue(value: "\(done)", suffix: "/\(periodTasks.count)", size: 34)
                Spacer()
                Text("\(Int((rate * 100).rounded()))%")
                    .font(Theme.number(15))
                    .foregroundStyle(Theme.secondaryText)
            }
            ProgressBar(value: rate, height: 8)
        }
        .card()
    }

    private func barCard(_ kind: LogKind) -> some View {
        let total = logs.total(kind, in: interval)
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle(kind)
            StatValue(value: TimeText.number(total), suffix: kind.unit, size: 34)
            bars(kind)
        }
        .card()
    }

    private var sleepCard: some View {
        let average = logs.total(.sleep, in: interval)
        return VStack(alignment: .leading, spacing: 12) {
            cardTitle(.sleep)
            HStack(alignment: .firstTextBaseline) {
                StatValue(value: TimeText.number(average), suffix: "h", size: 34)
                Spacer()
                Text("平均")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            bars(.sleep)
        }
        .card()
    }

    // MARK: - Helpers

    private func cardTitle(_ kind: LogKind) -> some View {
        HStack {
            Label(kind.title, systemImage: kind.icon)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                addingKind = kind
            } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.elevated))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(kind.title)を記録")
        }
    }

    @ViewBuilder
    private func bars(_ kind: LogKind) -> some View {
        let points = logs.chartPoints(kind, period: period, interval: interval)
        if points.allSatisfy({ $0.value == 0 }) {
            emptyText
        } else {
            let labels = period.axisLabels(for: period.buckets(for: interval))
            Chart(points) { point in
                BarMark(
                    x: .value("期間", point.label),
                    y: .value(kind.title, point.value)
                )
                .foregroundStyle(point.isHighlighted ? Color.white : Color.white.opacity(0.4))
                .cornerRadius(2)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: labels) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Theme.tertiaryText)
                }
            }
            .frame(height: 100)
        }
    }

    private var emptyText: some View {
        Text("まだ記録がありません。＋から追加できます。")
            .font(.caption)
            .foregroundStyle(Theme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
