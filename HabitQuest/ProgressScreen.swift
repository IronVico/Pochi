import SwiftData
import SwiftUI

/// One calendar for everything: orange when at least one habit was done,
/// green on a perfect day. Tap a past day to fix what was checked.
struct ProgressScreen: View {
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var monthOffset = 0
    @State private var editingDay: DayRef?

    private static let weekdays = ["L", "M", "M", "J", "V", "S", "D"]

    var body: some View {
        let month = Day.calendar.date(byAdding: .month, value: monthOffset, to: .now)!
        let todayKey = Day.key()
        let days = Self.monthGrid(month)
        let past = days.compactMap { $0 }.filter { Day.key($0) <= todayKey }
        let statuses = past.map { DayStatus(Day.key($0), habits: habits) }

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Progression")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 60)

                VStack(spacing: 16) {
                    HStack {
                        monthButton("chevron.left") { monthOffset -= 1 }
                        Spacer()
                        Text(Self.title(month))
                            .font(.system(size: 16, weight: .heavy, design: .monospaced))
                            .tracking(2)
                        Spacer()
                        monthButton("chevron.right") { monthOffset += 1 }
                            .disabled(monthOffset >= 0)
                            .opacity(monthOffset >= 0 ? 0.3 : 1)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(Self.weekdays.indices, id: \.self) { i in
                            Text(Self.weekdays[i]).font(Theme.mono(11)).foregroundStyle(.secondary)
                        }
                        ForEach(days.indices, id: \.self) { i in
                            if let date = days[i] {
                                let key = Day.key(date)
                                DayCell(date: date,
                                        status: DayStatus(key, habits: habits),
                                        isToday: key == todayKey,
                                        isFuture: key > todayKey)
                                    .onTapGesture {
                                        guard key <= todayKey, !habits.isEmpty else { return }
                                        editingDay = DayRef(date: date)
                                    }
                            } else {
                                Color.clear.aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }

                    HStack(spacing: 18) {
                        LegendItem(color: DayStatus.some.color, label: "Habitude validée")
                        LegendItem(color: DayStatus.perfect.color, label: "Journée parfaite")
                        Spacer()
                    }
                }
                .padding(16)
                .pixelPanel()
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 6) {
                    let active = statuses.filter { $0 != .none }.count
                    let perfect = statuses.filter { $0 == .perfect }.count
                    Text("\(active) \(active > 1 ? "jours actifs" : "jour actif") · \(perfect) \(perfect > 1 ? "journées parfaites" : "journée parfaite")")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text("Touche un jour pour corriger tes habitudes.")
                        .font(Theme.mono(12))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .sheet(item: $editingDay) { day in
            DayEditor(date: day.date)
                .presentationDetents([.medium, .large])
        }
    }

    private func monthButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 36, height: 36)
                .background(PixelFrame(unit: 2).fill(Color(white: 0.16)))
        }
        .foregroundStyle(.white)
    }

    /// The month's days, padded with `nil` so the 1st falls on its weekday (Monday first).
    private static func monthGrid(_ month: Date) -> [Date?] {
        let calendar = Day.calendar
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let count = calendar.range(of: .day, in: .month, for: first)!.count
        let leading = (calendar.component(.weekday, from: first) + 5) % 7 // Monday = 0
        return Array(repeating: nil, count: leading) + (0..<count).map { Day.offset($0, from: first) }
    }

    private static func title(_ month: Date) -> String {
        month.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "fr_FR"))).uppercased()
    }
}

enum DayStatus {
    case none, some, perfect

    /// Perfect when every habit that existed that day was done.
    init(_ key: String, habits: [Habit]) {
        let done = habits.filter { $0.isDone(key) }.count
        let active = habits.filter { Day.key($0.createdAt) <= key }
        if done == 0 {
            self = .none
        } else if !active.isEmpty && active.allSatisfy({ $0.isDone(key) }) {
            self = .perfect
        } else {
            self = .some
        }
    }

    var color: Color {
        switch self {
        case .none: Color(white: 0.15)
        case .some: Theme.accent
        case .perfect: Color(red: 0.36, green: 0.82, blue: 0.48)
        }
    }
}

struct DayCell: View {
    let date: Date
    let status: DayStatus
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        PixelFrame(unit: 2)
            .fill(status.color)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Text("\(Day.calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(status == .none ? Color.secondary : Color.black.opacity(0.8))
                    .fixedSize()
            }
            .overlay {
                if isToday { PixelFrame(unit: 2).stroke(.white, lineWidth: 2) }
            }
            .opacity(isFuture ? 0.35 : 1)
            .contentShape(.rect)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(color).frame(width: 12, height: 12)
            Text(label).font(Theme.mono(11)).foregroundStyle(.secondary)
        }
    }
}

struct DayRef: Identifiable {
    let date: Date
    var id: String { Day.key(date) }
}

/// Check or uncheck habits for a past day.
struct DayEditor: View {
    let date: Date
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Environment(\.dismiss) private var dismiss

    private var title: String {
        let text = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "fr_FR")))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    var body: some View {
        let key = Day.key(date)

        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(habits) { habit in
                        let done = habit.isDone(key)
                        Button {
                            withAnimation(.snappy) { habit.toggle(key) }
                            if habit.isDone(key) { Haptics.check(combo: 1) } else { Haptics.uncheck() }
                        } label: {
                            HStack(spacing: 12) {
                                EmojiIcon(emoji: habit.emoji, size: 22)
                                    .frame(width: 38, height: 38)
                                    .background(PixelFrame(unit: 2).fill(habit.color.opacity(0.2)))
                                Text(habit.name).font(.system(size: 16, weight: .semibold))
                                Spacer()
                                PixelCheckbox(done: done, color: habit.color)
                            }
                            .padding(12)
                            .pixelPanel(border: done ? habit.color : Color(white: 0.2))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
