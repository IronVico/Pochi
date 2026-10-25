import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)

        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatTile(value: "\(stats.totalXP)", label: "XP total", symbol: "bolt.fill", color: .purple)
                        StatTile(value: "\(stats.totalChecks)", label: "Validations", symbol: "checkmark.circle.fill", color: .green)
                        StatTile(value: "\(stats.bestStreak) j", label: "Meilleure série", symbol: "flame.fill", color: .orange)
                        StatTile(value: "\(stats.perfectDays)", label: "Journées parfaites", symbol: "sparkles", color: .pink)
                    }

                    if !habits.isEmpty {
                        Text("Oublié de cocher un jour ? Touche une case pour la corriger.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 6)
                    }

                    ForEach(habits) { habit in
                        HabitHeatmap(habit: habit)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progression")
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).foregroundStyle(color).font(.title3)
            Text(value).font(.title2.bold().monospacedDigit()).contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}

/// Last 5 weeks, aligned so each column is a weekday (Monday first).
struct HabitHeatmap: View {
    let habit: Habit

    private static let weeks = 5
    private static let weekdays = ["L", "M", "M", "J", "V", "S", "D"]

    /// Days from the Monday 4 weeks before this week, through Sunday of this week.
    private var days: [Date] {
        let today = Date.now
        let weekday = (Day.calendar.component(.weekday, from: today) + 5) % 7 // Monday = 0
        let start = Day.offset(-weekday - 7 * (Self.weeks - 1), from: today)
        return (0..<(7 * Self.weeks)).map { Day.offset($0, from: start) }
    }

    var body: some View {
        let todayKey = Day.key()

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(habit.emoji)
                Text(habit.name).font(.headline)
                Spacer()
                Label("\(habit.bestStreak) max", systemImage: "flame.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Self.weekdays.indices, id: \.self) { i in
                    Text(Self.weekdays[i]).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(days, id: \.self) { date in
                    let key = Day.key(date)
                    let future = key > todayKey
                    let done = habit.isDone(key)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(done ? habit.color : Color(.tertiarySystemFill))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if key == todayKey {
                                RoundedRectangle(cornerRadius: 6).strokeBorder(habit.color, lineWidth: 2)
                            }
                        }
                        .opacity(future ? 0.3 : 1)
                        .onTapGesture {
                            guard !future else { return }
                            withAnimation(.snappy) { habit.toggle(key) }
                        }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}
