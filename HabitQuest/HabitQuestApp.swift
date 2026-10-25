import SwiftData
import SwiftUI

@main
struct HabitQuestApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Habit.self)
    }
}

struct RootView: View {
    @Query private var habits: [Habit]
    @State private var confetti = 0
    @State private var levelUp: Int?

    var body: some View {
        let stats = GameStats(habits: habits)

        TabView {
            Tab("Aujourd'hui", systemImage: "checkmark.circle.fill") {
                TodayView()
            }
            Tab("Progression", systemImage: "chart.bar.fill") {
                ProgressScreen()
            }
            Tab("Badges", systemImage: "trophy.fill") {
                BadgesView()
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
            confetti += 1
        }
        .onChange(of: stats.isPerfectToday) { _, perfect in
            if perfect { confetti += 1 }
        }
    }
}
