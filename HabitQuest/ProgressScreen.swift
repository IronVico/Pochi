import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Progression")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 60)

                LevelPanel(stats: stats)
                    .padding(.top, 24)

                SectionLabel(text: "STATS")
                    .padding(.top, 36)
                    .padding(.bottom, 14)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatTile(icon: PixelIcon.bolt, value: "\(stats.totalXP)", label: "XP TOTAL")
                    StatTile(icon: PixelIcon.check, value: "\(stats.totalChecks)", label: "VALIDATIONS")
                    StatTile(icon: PixelIcon.flame, value: "\(stats.bestStreak)", label: "RECORD (J)")
                    StatTile(icon: PixelIcon.sparkle, value: "\(stats.perfectDays)", label: "JOURNÉES PARFAITES")
                }

                if !habits.isEmpty {
                    SectionLabel(text: "CALENDRIER")
                        .padding(.top, 36)
                    Text("Oublié de cocher un jour ? Touche une case pour la corriger.")
                        .font(Theme.mono(12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                        .padding(.bottom, 14)
                    VStack(spacing: 12) {
                        ForEach(habits) { habit in
                            HabitHeatmap(habit: habit)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }
}

/// Current level, title and progress to the next one, in blocks.
struct LevelPanel: View {
    let stats: GameStats

    private static let blocks = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                PixelSprite(grid: PixelIcon.star, pixel: 2)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 }
                Text("NIVEAU \(stats.level)")
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .contentTransition(.numericText())
                Spacer()
                Text(stats.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            PixelBlocksBar(filled: Int(stats.progress * Double(Self.blocks)), total: Self.blocks)
            Text("\(stats.xpInLevel) / \(stats.xpNeeded) XP · niveau \(stats.level + 1) dans \(stats.xpNeeded - stats.xpInLevel) XP")
                .font(Theme.mono(12))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .pixelPanel(border: Theme.accent.opacity(0.6))
    }
}

struct StatTile: View {
    let icon: [String]
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PixelSprite(grid: icon, pixel: 2)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .contentTransition(.numericText())
            Text(label)
                .font(Theme.mono(10))
                .tracking(1)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pixelPanel()
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

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                EmojiIcon(emoji: habit.emoji, size: 20)
                Text(habit.name).font(.headline)
                Spacer()
                PixelSprite(grid: PixelIcon.flame, pixel: 1.1)
                Text("\(habit.bestStreak) max")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(Self.weekdays.indices, id: \.self) { i in
                    Text(Self.weekdays[i]).font(Theme.mono(11)).foregroundStyle(.secondary)
                }
                ForEach(days, id: \.self) { date in
                    let key = Day.key(date)
                    let future = key > todayKey
                    let done = habit.isDone(key)
                    Rectangle()
                        .fill(done ? habit.color : Color(white: 0.17))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if key == todayKey {
                                Rectangle().strokeBorder(done ? .white : habit.color, lineWidth: 3)
                            }
                        }
                        .opacity(future ? 0.3 : 1)
                        .onTapGesture {
                            guard !future else { return }
                            withAnimation(.snappy) { habit.toggle(key) }
                            if habit.isDone(key) { Haptics.check(combo: 1) } else { Haptics.uncheck() }
                        }
                }
            }
        }
        .padding(16)
        .pixelPanel()
    }
}
