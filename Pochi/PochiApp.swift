import SwiftData
import SwiftUI

@main
struct PochiApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-corgiGallery") {
                CorgiGallery()
            } else if CommandLine.arguments.contains("-nicheGallery") {
                NicheGallery()
            } else if CommandLine.arguments.contains("-iconGallery") {
                DoodleGallery()
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
    @AppStorage(Appearance.key) private var appearance = Appearance.system
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let stats = GameStats(habits: habits)

        TabView {
            Tab {
                TodayView()
            } label: {
                Label("Aujourd'hui", systemImage: "checkmark.circle")
            }
            Tab {
                ProgressScreen()
            } label: {
                Label("Progression", systemImage: "chart.bar")
            }
            Tab {
                NicheScreen()
            } label: {
                Label("Niche", systemImage: "house")
            }
        }
        .tint(Theme.accent)
        .onChange(of: appearance, initial: true) { _, appearance in appearance.apply() }
        // Health data moves through the day (steps): reread it whenever the app comes back.
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { Task { await Health.shared.refresh() } }
        }
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
    /// Launch with `-seedDemo` to replace the data with sample habits (simulator testing),
    /// or `-seedNeglected` for the same habits abandoned for 4 days.
    private func seedDemoIfRequested() {
        let neglected = CommandLine.arguments.contains("-seedNeglected")
        guard CommandLine.arguments.contains("-seedDemo") || neglected else { return }
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
            // `-seedNeglected`: same history, but nothing done for the last 4 days.
            if neglected { habit.completedDays = habit.completedDays.map { Day.key(Day.offset(-4, from: Day.date($0)!)) } }
            context.insert(habit)
        }
    }
    #endif
}
