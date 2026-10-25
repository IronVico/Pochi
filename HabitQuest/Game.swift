import Foundation

enum Game {
    static let baseXP = 10
    static let perfectDayXP = 25

    /// 10 XP per check-in, +2 per day of streak, capped at +20 (11 days in a row).
    static func xp(forRun run: Int) -> Int { baseXP + min(max(run - 1, 0), 10) * 2 }

    /// Level n → n+1 costs n × 100 XP.
    static func xpNeeded(forLevel level: Int) -> Int { level * 100 }

    static func title(forLevel level: Int) -> String {
        switch level {
        case ..<3: "Débutant 🌱"
        case 3..<5: "Apprenti 🌿"
        case 5..<8: "Régulier 🌳"
        case 8..<12: "Discipliné ⚔️"
        case 12..<20: "Machine 🤖"
        default: "Légende 👑"
        }
    }
}

struct GameStats {
    var totalXP = 0
    var level = 1
    var xpInLevel = 0
    var xpNeeded = 100
    var totalChecks = 0
    var perfectDays = 0
    var bestStreak = 0
    var currentStreak = 0
    var habitCount = 0
    var todayDone = 0

    var progress: Double { Double(xpInLevel) / Double(xpNeeded) }
    var title: String { Game.title(forLevel: level) }
    var isPerfectToday: Bool { habitCount > 0 && todayDone == habitCount }

    init(habits: [Habit]) {
        let today = Day.key()
        habitCount = habits.count
        todayDone = habits.filter { $0.isDone(today) }.count
        totalChecks = habits.reduce(0) { $0 + Set($1.completedDays).count }
        bestStreak = habits.map(\.bestStreak).max() ?? 0
        currentStreak = habits.map(\.currentStreak).max() ?? 0

        // A day is perfect when every habit that existed that day was checked.
        let days = Set(habits.flatMap(\.completedDays))
        perfectDays = days.filter { day in
            let active = habits.filter { Day.key($0.createdAt) <= day }
            return !active.isEmpty && active.allSatisfy { $0.isDone(day) }
        }.count

        totalXP = habits.reduce(0) { $0 + $1.xp } + perfectDays * Game.perfectDayXP

        var remaining = totalXP
        while remaining >= Game.xpNeeded(forLevel: level) {
            remaining -= Game.xpNeeded(forLevel: level)
            level += 1
        }
        xpInLevel = remaining
        xpNeeded = Game.xpNeeded(forLevel: level)
    }
}

/// What each level adds to Pochi's doghouse (see IsoWorld).
struct BuildStep: Identifiable {
    let level: Int
    let name: String
    var id: Int { level }
}

enum Construction {
    static let steps: [BuildStep] = [
        BuildStep(level: 1, name: "Le terrain"),
        BuildStep(level: 2, name: "Les fondations"),
        BuildStep(level: 3, name: "Les murs"),
        BuildStep(level: 4, name: "Le toit"),
        BuildStep(level: 5, name: "La gamelle"),
        BuildStep(level: 6, name: "La clôture"),
        BuildStep(level: 7, name: "Le chemin"),
        BuildStep(level: 8, name: "Le lampadaire"),
        BuildStep(level: 9, name: "La boîte aux lettres"),
        BuildStep(level: 10, name: "Le drapeau"),
    ]

    static func step(at level: Int) -> BuildStep? { steps.first { $0.level == level } }
    static func next(after level: Int) -> BuildStep? { steps.first { $0.level > level } }
}
