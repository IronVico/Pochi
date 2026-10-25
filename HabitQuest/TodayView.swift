import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var showAdd = false
    @State private var editing: Habit?
    @State private var nudge = 0

    private static let suggestions: [(String, String, String)] = [
        ("Boire 2L d'eau", "💧", "blue"),
        ("Faire du sport", "🏃", "orange"),
        ("Lire 20 minutes", "📚", "purple"),
        ("Méditer", "🧘", "teal"),
    ]

    var body: some View {
        let stats = GameStats(habits: habits)
        let mood = CorgiMood(stats: stats)
        let verdict = mood.verdict

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                HStack(spacing: 10) {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(stats.currentStreak > 0 ? Theme.accent : .secondary)
                        Text("\(stats.currentStreak)").contentTransition(.numericText())
                    }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(Color(white: 0.12), in: .capsule)

                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 46, height: 46)
                            .background(Color(white: 0.12), in: .circle)
                    }
                    .foregroundStyle(.white)
                }

                Text(Self.weekday)
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 14)

                // Corgi
                HStack(alignment: .center, spacing: 14) {
                    PixelCorgi(sleeping: mood == .nothing || mood == .empty) { nudge += 1 }
                    SpeechBubble(text: mood.line(nudge: nudge))
                }
                .padding(.top, 26)

                // Big XP number
                Text("XP")
                    .font(Theme.mono(18))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                Text("\(stats.totalXP)")
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.heat)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(white: 0.13))
                        Capsule()
                            .fill(Theme.heat)
                            .frame(width: max(18, geo.size.width * stats.progress))
                    }
                }
                .frame(height: 18)
                .padding(.top, 10)

                Text("Niveau \(stats.level + 1) dans \(stats.xpNeeded - stats.xpInLevel) XP")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 10)

                // Stats
                VStack(spacing: 24) {
                    StatLine(symbol: "star.fill", label: "NIVEAU", value: "\(stats.level)", unit: stats.title)
                    StatLine(symbol: "checkmark", label: "AUJOURD'HUI", value: "\(stats.todayDone)", unit: "/ \(stats.habitCount)")
                    StatLine(symbol: "flame.fill", label: "RECORD", value: "\(stats.bestStreak)", unit: stats.bestStreak > 1 ? "jours" : "jour")
                }
                .padding(.vertical, 36)

                Rectangle().fill(Color(white: 0.15)).frame(height: 1)

                HStack {
                    Text("VERDICT").font(Theme.mono(18)).tracking(2)
                    Spacer()
                    VerdictStamp(text: verdict.text, color: verdict.color)
                        .id(verdict.text)
                        .transition(.scale(scale: 1.8).combined(with: .opacity))
                }
                .padding(.vertical, 30)
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: verdict.text)

                // Habits
                Text("HABITUDES")
                    .font(Theme.mono(24))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                VStack(spacing: 12) {
                    if habits.isEmpty {
                        emptyState
                    } else {
                        ForEach(habits) { habit in
                            HabitRow(habit: habit) {
                                withAnimation(.spring(duration: 0.35)) { habit.toggle() }
                            }
                            .contextMenu {
                                Button("Modifier", systemImage: "pencil") { editing = habit }
                                Button("Supprimer", systemImage: "trash", role: .destructive) {
                                    withAnimation { context.delete(habit) }
                                }
                            }
                            .onTapGesture { editing = habit }
                        }
                    }

                    if stats.isPerfectToday {
                        PerfectDayBanner()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring, value: stats.isPerfectToday)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .sheet(isPresented: $showAdd) {
            HabitEditor(habit: nil, nextOrder: (habits.map(\.order).max() ?? -1) + 1)
        }
        .sheet(item: $editing) { habit in
            HabitEditor(habit: habit, nextOrder: habit.order)
        }
    }

    private static var weekday: String {
        let text = Date.now.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "fr_FR")))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choisis une suggestion ou appuie sur +")
                .font(Theme.mono(14))
                .foregroundStyle(.secondary)

            ForEach(Array(Self.suggestions.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation {
                        context.insert(Habit(name: item.0, emoji: item.1, colorName: item.2, order: index))
                    }
                } label: {
                    HStack {
                        Text(item.1)
                        Text(item.0)
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundStyle(HabitColor.color(item.2))
                    }
                    .padding(14)
                    .background(Color(white: 0.11), in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StatLine: View {
    let symbol: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
            Text(label)
                .font(Theme.mono(18))
                .tracking(2)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PerfectDayBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("✨").font(.title)
            VStack(alignment: .leading) {
                Text("Journée parfaite !").font(.headline)
                Text("+\(Game.perfectDayXP) XP bonus").font(.subheadline).opacity(0.9)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Theme.heat, in: .rect(cornerRadius: 18))
    }
}

// MARK: - Habit row

struct HabitRow: View {
    let habit: Habit
    let onToggle: () -> Void
    @State private var floatingXP: Int?

    var body: some View {
        let done = habit.isDone()
        let streak = habit.currentStreak

        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(habit.color.opacity(0.18), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name).font(.headline)
                HStack(spacing: 10) {
                    Label("\(streak)", systemImage: "flame.fill")
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                        .contentTransition(.numericText())
                    Text(done ? "Validé" : "+\(habit.nextXP) XP")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                WeekDots(habit: habit)
            }

            Spacer()

            Button {
                if !done {
                    floatingXP = habit.nextXP
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { floatingXP = nil }
                }
                onToggle()
            } label: {
                ZStack {
                    Circle().fill(done ? habit.color : .clear)
                    Circle().strokeBorder(habit.color, lineWidth: 3)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .transition(.scale)
                    }
                }
                .frame(width: 46, height: 46)
                .scaleEffect(done ? 1.0 : 0.92)
                .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: done) { _, new in new }
            .overlay(alignment: .top) {
                if let floatingXP {
                    Text("+\(floatingXP) XP")
                        .font(.caption.bold())
                        .foregroundStyle(habit.color)
                        .fixedSize()
                        .offset(y: -30)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity.combined(with: .offset(y: -20))
                        ))
                }
            }
            .animation(.easeOut(duration: 0.4), value: floatingXP)
        }
        .padding(14)
        .background(Color(white: 0.11), in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
    }
}

/// The last 7 days, today on the right.
struct WeekDots: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 4) {
            ForEach((0..<7).reversed(), id: \.self) { ago in
                let done = habit.isDone(Day.key(Day.offset(-ago)))
                Circle()
                    .fill(done ? habit.color : Color(.tertiarySystemFill))
                    .frame(width: 8, height: 8)
                    .overlay {
                        if ago == 0 { Circle().strokeBorder(habit.color.opacity(0.6), lineWidth: 1).padding(-2) }
                    }
            }
        }
    }
}
