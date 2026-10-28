import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var showAdd = false
    @State private var editing: Habit?
    @State private var nudge = 0
    @State private var explainedNeed: CareNeed?
    @AppStorage(Sound.enabledKey) private var soundOn = true

    private static let suggestions: [(String, String, String)] = [
        ("Boire 2L d'eau", "💧", "blue"),
        ("Faire du sport", "🏃", "orange"),
        ("Lire 20 minutes", "📚", "purple"),
        ("Méditer", "🧘", "teal"),
    ]

    var body: some View {
        let stats = GameStats(habits: habits)
        let care = PochiCare(habits: habits)
        let mood = CorgiMood(stats: stats, care: care)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                HStack(spacing: 10) {
                    Button { soundOn.toggle() } label: {
                        Image(systemName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 46, height: 46)
                            .background(Circle().fill(soundOn ? Theme.yellow : Theme.card))
                            .overlay { Circle().strokeBorder(Theme.ink, lineWidth: Theme.outline) }
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(PressableStyle(radius: 23))
                    .foregroundStyle(soundOn ? Theme.ink : Theme.ink.opacity(0.4))
                    .accessibilityLabel(soundOn ? "Couper le son" : "Activer le son")
                    Spacer()
                    HStack(spacing: 6) {
                        Doodle(symbol: "flame", fill: stats.currentStreak > 0 ? Theme.coral : Theme.paper, size: 18)
                        Text("\(stats.currentStreak)").contentTransition(.numericText())
                    }
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .sketchCard(radius: 23)

                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .heavy))
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.coral))
                            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.ink, lineWidth: Theme.outline) }
                    }
                    .buttonStyle(PressableStyle(radius: 14))
                    .foregroundStyle(Theme.ink)
                }

                Text(Self.weekday)
                    .font(Theme.title(46))
                    .tracking(-1)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 18)

                // Corgi
                HStack(alignment: .center, spacing: 4) {
                    PochiView(pose: mood.pose) { nudge += 1 }
                        .id(mood.pose)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    SpeechBubble(text: mood.line(nudge: nudge))
                }
                .padding(.top, 26)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: mood.pose)

                if !habits.isEmpty {
                    CareGauges(care: care) { explainedNeed = $0 }
                        .padding(.top, 18)
                }

                // Habits
                Text("Ta journée")
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 40)
                    .padding(.bottom, 16)

                if habits.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 12) {
                        ForEach(habits) { habit in
                            HabitCard(habit: habit) { toggle(habit) }
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(DottedPaper())
        .sheet(item: $explainedNeed) { need in
            CareNeedSheet(need: need, value: need.value(in: care))
                .presentationDragIndicator(.visible)
                .presentationBackground { DottedPaper() }
        }
        .sheet(isPresented: $showAdd) {
            HabitEditor(habit: nil, nextOrder: (habits.map(\.order).max() ?? -1) + 1)
        }
        .sheet(item: $editing) { habit in
            HabitEditor(habit: habit, nextOrder: habit.order)
        }
    }

    private func toggle(_ habit: Habit) {
        withAnimation(.spring(duration: 0.35)) { habit.toggle() }
        let doneToday = habits.filter { $0.isDone() }.count
        if !habit.isDone() {
            Feedback.uncheck()
        } else if doneToday == habits.count {
            Feedback.perfectDay()
        } else {
            Feedback.check(combo: doneToday)
        }
    }

    private static var weekday: String {
        let text = Date.now.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "fr_FR")))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("choisis une idée, ou appuie sur +")
                .handNote(Theme.periwinkle, size: 17, tilt: -2)
                .padding(.bottom, 4)

            ForEach(Array(Self.suggestions.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation {
                        context.insert(Habit(name: item.0, emoji: item.1, colorName: item.2, order: index))
                    }
                    Feedback.added()
                } label: {
                    HStack {
                        EmojiIcon(emoji: item.1, size: 20, fill: HabitColor.color(item.2))
                        Text(item.0).font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(HabitColor.color(item.2)))
                            .overlay { Circle().strokeBorder(Theme.ink, lineWidth: 2) }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.ink, lineWidth: Theme.outline) }
                }
                .buttonStyle(PressableStyle(radius: 16))
            }
        }
    }
}

// MARK: - Habit card

struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void
    @State private var floatingXP: Int?
    @State private var shake = 0

    var body: some View {
        let done = habit.isDone()
        let streak = habit.currentStreak

        Button {
            if !done {
                floatingXP = habit.nextXP
                shake += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { floatingXP = nil }
            }
            onToggle()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    EmojiIcon(emoji: habit.emoji, size: 26, fill: habit.color)
                        .frame(width: 46, height: 46)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.ink, lineWidth: 2) }
                    Spacer()
                    CheckCircle(done: done, color: habit.color)
                }

                Text(habit.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 14)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Doodle(symbol: "flame", fill: streak > 0 ? Theme.coral : Theme.paper, size: 12)
                        Text("\(streak)").contentTransition(.numericText())
                    }
                    .foregroundStyle(streak > 0 ? Theme.ink : Theme.ink.opacity(0.45))
                    Text(done ? "VALIDÉ" : "+\(habit.nextXP) XP")
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .padding(.top, 6)

                WeekSquares(habit: habit)
                    .padding(.top, 12)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // Paper face that takes the habit's colour once done, then the ink outline.
                RoundedRectangle(cornerRadius: 18).fill(done ? habit.color : Theme.card)
                RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.ink, lineWidth: Theme.outline)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(PressableStyle())
        // Checking a habit: the card pops and wobbles.
        .keyframeAnimator(initialValue: Wobble(), trigger: shake) { card, wobble in
            card
                .rotationEffect(.degrees(wobble.angle))
                .scaleEffect(wobble.scale)
        } keyframes: { _ in
            KeyframeTrack(\.angle) {
                CubicKeyframe(-3.5, duration: 0.07)
                CubicKeyframe(3, duration: 0.08)
                CubicKeyframe(-2, duration: 0.08)
                CubicKeyframe(1, duration: 0.07)
                CubicKeyframe(0, duration: 0.08)
            }
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.06, duration: 0.12, spring: .snappy)
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            }
        }
        .overlay(alignment: .topTrailing) {
            if let floatingXP {
                Text("+\(floatingXP) XP")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.yellow))
                    .overlay { Capsule().strokeBorder(Theme.ink, lineWidth: 2) }
                    .rotationEffect(.degrees(-4))
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

private struct Wobble {
    var angle = 0.0
    var scale = 1.0
}

/// Round ink-outlined checkbox; a pixel check mark pops in when done.
struct CheckCircle: View {
    let done: Bool
    let color: Color

    var body: some View {
        ZStack {
            Circle().fill(done ? Theme.ink : Theme.card)
            Circle().strokeBorder(Theme.ink, lineWidth: Theme.outline)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(color)
                    .transition(.scale(scale: 0.2).animation(.spring(response: 0.3, dampingFraction: 0.45)))
            }
        }
        .frame(width: 30, height: 30)
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
            .foregroundStyle(Theme.ink.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 150)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Theme.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(PressableStyle(shadow: .clear))
    }
}

/// The card rests on a hard ink shadow and sinks onto it while pressed, with a small tick.
struct PressableStyle: ButtonStyle {
    var shadow: Color = Theme.ink
    var radius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(Sinks(pressed: configuration.isPressed, shadow: shadow, radius: radius))
    }
}

/// The last 7 days as little squares, today on the right.
struct WeekSquares: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 4) {
            ForEach((0..<7).reversed(), id: \.self) { ago in
                let done = habit.isDone(Day.key(Day.offset(-ago)))
                RoundedRectangle(cornerRadius: 2)
                    .fill(done ? Theme.ink : Theme.ink.opacity(0.12))
                    .frame(width: 9, height: 9)
                    .overlay {
                        if ago == 0 { RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1.5).padding(-3) }
                    }
                    .padding(.horizontal, ago == 0 ? 2 : 0)
            }
        }
    }
}

// MARK: - Pochi's needs

/// One of Pochi's three gauges (see PochiCare), with what the app tells you about it.
enum CareNeed: String, Identifiable, CaseIterable {
    case food, happiness, energy

    var id: String { rawValue }

    func value(in care: PochiCare) -> Double {
        switch self {
        case .food: care.food
        case .happiness: care.happiness
        case .energy: care.energy
        }
    }

    var label: String {
        switch self {
        case .food: "FAIM"
        case .happiness: "MORAL"
        case .energy: "ÉNERGIE"
        }
    }

    @ViewBuilder func icon(size: CGFloat) -> some View {
        switch self {
        case .food: BoneDoodle(fill: color, size: size)
        case .happiness: Doodle(symbol: "heart", fill: color, size: size)
        case .energy: Doodle(symbol: "bolt", fill: color, size: size)
        }
    }

    var color: Color {
        switch self {
        case .food: Theme.coral
        case .happiness: Theme.pink
        case .energy: Theme.yellow
        }
    }

    var summary: String {
        switch self {
        case .food: "Sa gamelle. Elle se remplit à chaque habitude cochée."
        case .happiness: "Son moral. Il suit la part de ta journée que tu termines."
        case .energy: "Sa forme. Elle récompense la régularité, pas la quantité."
        }
    }

    var rises: String {
        switch self {
        case .food: "+18 par habitude cochée."
        case .happiness: "Jusqu'à +45 selon la part de ta journée faite. +15 pour une journée parfaite."
        case .energy: "+25 dès que tu coches au moins une habitude dans la journée."
        }
    }

    var drops: String {
        switch self {
        case .food: "−40 par jour. C'est la jauge qui se vide le plus vite."
        case .happiness: "−25 par jour."
        case .energy: "−22 par jour."
        }
    }

    var tip: String {
        switch self {
        case .food: "Coche plusieurs habitudes par jour pour qu'il reste rassasié."
        case .happiness: "Vise les journées parfaites : c'est ce qui le rend le plus heureux."
        case .energy: "Une seule habitude par jour suffit à la garder haute. Ne saute pas de jour."
        }
    }
}

/// Hunger, happiness and energy, as small block bars. Tap one to learn how it works.
struct CareGauges: View {
    let care: PochiCare
    let onSelect: (CareNeed) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CareNeed.allCases) { need in
                Button { onSelect(need) } label: {
                    Gauge(need: need, value: need.value(in: care))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private struct Gauge: View {
        let need: CareNeed
        let value: Double

        private static let blocks = 5

        var body: some View {
            let filled = Int((value / 100 * Double(Self.blocks)).rounded(.up))
            let low = value < 25

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    need.icon(size: 13)
                    Text(need.label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(low ? Theme.accent : Theme.ink.opacity(0.6))
                }
                BlocksBar(filled: filled, total: Self.blocks, color: need.color, height: 10)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sketchCard(shadow: low ? Theme.accent : Theme.ink, radius: 14)
            .contentShape(.rect)
        }
    }
}

/// Bottom sheet explaining one gauge: where it stands, what fills it, what empties it.
/// Sized to its content, so every gauge's sheet is just as tall as it needs.
struct CareNeedSheet: View {
    let need: CareNeed
    let value: Double

    @State private var height: CGFloat = 400

    private var state: String {
        switch value {
        case 70...: "Au top"
        case 40..<70: "Ça va"
        case 25..<40: "Bas"
        default: "Critique"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                need.icon(size: 28)
                    .frame(width: 56, height: 56)
                    .sketchCard(fill: Theme.card, radius: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text(need.label)
                        .font(Theme.title(24))
                    Text(need.summary)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Maintenant")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                    Spacer()
                    Text("\(state) · \(Int(value.rounded()))/100")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(value < 25 ? Theme.accent : Theme.ink)
                }
                BlocksBar(filled: Int((value / 10).rounded(.up)), total: 10, color: need.color)
            }
            .padding(14)
            .sketchCard()

            VStack(alignment: .leading, spacing: 16) {
                Row(symbol: "arrow.up", title: "ÇA MONTE", text: need.rises, color: need.color)
                Row(symbol: "arrow.down", title: "ÇA BAISSE", text: need.drops, color: need.color)
                Row(symbol: "lightbulb.fill", title: "ASTUCE", text: need.tip, color: need.color)
            }

            HStack(alignment: .top, spacing: 12) {
                Doodle(symbol: "heart", fill: Theme.pink, size: 14)
                    .padding(.top, 3)
                Text("Si ses jauges sont trop basses et que rien n'est coché, Pochi boude. Une seule habitude cochée suffit à le consoler.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sketchCard(fill: Theme.yellow.opacity(0.45))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 16)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .presentationDetents([.height(height)])
    }

    private struct Row: View {
        let symbol: String
        let title: String
        let text: String
        let color: Color

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 20)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(color)
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
