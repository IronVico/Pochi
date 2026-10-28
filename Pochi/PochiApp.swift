import SwiftData
import SwiftUI

@main
struct PochiApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-corgiGallery") {
                CorgiGallery().preferredColorScheme(.dark)
            } else if CommandLine.arguments.contains("-nicheGallery") {
                NicheGallery().preferredColorScheme(.dark)
            } else if CommandLine.arguments.contains("-iconGallery") {
                PixelEmojiGallery().preferredColorScheme(.dark)
            } else {
                RootView()
            }
            #else
            RootView()
            #endif
        }
        .modelContainer(for: Habit.self)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @State private var confetti = 0
    @State private var levelUp: Int?

    var body: some View {
        let stats = GameStats(habits: habits)

        TabView {
            Tab {
                TodayView()
            } label: {
                Label { Text("Aujourd'hui") } icon: { PixelIcon.templateImage(PixelIcon.check) }
            }
            Tab {
                ProgressScreen()
            } label: {
                Label { Text("Progression") } icon: { PixelIcon.templateImage(PixelIcon.chart) }
            }
            Tab {
                NicheScreen()
            } label: {
                Label { Text("Niche") } icon: { PixelIcon.templateImage(PixelIcon.house) }
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .overlay {
            ConfettiView(trigger: confetti)
                .allowsHitTesting(false)
        }
        .overlay {
            if let levelUp {
                LevelUpView(level: levelUp) {
                    withAnimation { self.levelUp = nil }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onChange(of: stats.level) { old, new in
            guard new > old else { return }
            withAnimation(.spring) { levelUp = new }
            Feedback.levelUp()
            confetti += 1
        }
        #if DEBUG
        .task {
            seedDemoIfRequested()
            // Launch with `-levelUp` to see the level-up screen.
            if CommandLine.arguments.contains("-levelUp") { levelUp = stats.level }
        }
        #endif
        .onChange(of: stats.isPerfectToday) { _, perfect in
            if perfect { confetti += 1 }
        }
    }

    #if DEBUG
    /// Launch with `-seedDemo` to replace the data with sample habits (simulator testing).
    private func seedDemoIfRequested() {
        guard CommandLine.arguments.contains("-seedDemo") else { return }
        try? context.delete(model: Habit.self)
        let samples = [
            ("Boire 2L d'eau", "💧", "blue", 6), ("Faire du sport", "🏃", "orange", 2),
            ("Lire 20 minutes", "📚", "purple", 11), ("Méditer", "🧘", "teal", 0),
            ("Pas d'écran au lit", "📵", "red", 3),
        ]
        for (i, (name, emoji, color, streak)) in samples.enumerated() {
            let habit = Habit(name: name, emoji: emoji, colorName: color, order: i)
            habit.createdAt = Day.offset(-30)
            habit.completedDays = (1...max(streak, 1)).map { Day.key(Day.offset(-$0)) }.filter { _ in streak > 0 }
            context.insert(habit)
        }
    }
    #endif
}
