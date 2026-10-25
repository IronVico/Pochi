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
                HStack(alignment: .center, spacing: 4) {
                    PixelCorgi(pose: mood.pose) { nudge += 1 }
                        .id(mood.pose)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    SpeechBubble(text: mood.line(nudge: nudge))
                }
                .padding(.top, 26)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: mood.pose)

                // Habits
                Text("HABITUDES")
                    .font(Theme.mono(24))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                    .padding(.bottom, 14)

                if habits.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(habits) { habit in
                            HabitCard(habit: habit) {
                                withAnimation(.spring(duration: 0.35)) { habit.toggle() }
                            }
                            .contextMenu {
                                Button("Modifier", systemImage: "pencil") { editing = habit }
                                Button("Supprimer", systemImage: "trash", role: .destructive) {
                                    withAnimation { context.delete(habit) }
                                }
                            }
                        }
                        AddHabitCard { showAdd = true }
                    }
                }

                if stats.isPerfectToday {
                    PerfectDayBanner()
                        .padding(.top, 12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring, value: stats.isPerfectToday)
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

// MARK: - Habit card

struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void
    @State private var floatingXP: Int?

    var body: some View {
        let done = habit.isDone()
        let streak = habit.currentStreak

        Button {
            if !done {
                floatingXP = habit.nextXP
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { floatingXP = nil }
            }
            onToggle()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(habit.emoji)
                        .font(.title2)
                        .frame(width: 46, height: 46)
                        .background(habit.color.opacity(done ? 0.35 : 0.18), in: .rect(cornerRadius: 14))
                    Spacer()
                    ZStack {
                        Circle().fill(done ? habit.color : .clear)
                        Circle().strokeBorder(done ? habit.color : Color(white: 0.3), lineWidth: 2.5)
                        if done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .transition(.scale)
                        }
                    }
                    .frame(width: 30, height: 30)
                }

                Text(habit.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 14)

                HStack(spacing: 8) {
                    Label("\(streak)", systemImage: "flame.fill")
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                        .contentTransition(.numericText())
                    Text(done ? "Validé" : "+\(habit.nextXP) XP")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .padding(.top, 6)

                WeekDots(habit: habit)
                    .padding(.top, 12)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(white: 0.11))
                    .overlay {
                        if done {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(LinearGradient(colors: [habit.color.opacity(0.28), habit.color.opacity(0.06)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(done ? habit.color.opacity(0.6) : .clear, lineWidth: 1.5)
            }
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(PressableStyle())
        .sensoryFeedback(.success, trigger: done) { _, new in new }
        .overlay(alignment: .topTrailing) {
            if let floatingXP {
                Text("+\(floatingXP) XP")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(habit.color)
                    .fixedSize()
                    .offset(x: -8, y: -14)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity.combined(with: .offset(y: -20))
                    ))
            }
        }
        .animation(.easeOut(duration: 0.4), value: floatingXP)
    }
}

struct AddHabitCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                Text("AJOUTER")
                    .font(Theme.mono(13))
                    .tracking(2)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 150)
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Color(white: 0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Slight shrink while pressed.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
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
