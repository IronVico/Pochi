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

struct Badge: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let detail: String
    let isUnlocked: (GameStats) -> Bool

    static let all: [Badge] = [
        Badge(id: "first", emoji: "👣", title: "Premier pas", detail: "Valider une habitude") { $0.totalChecks >= 1 },
        Badge(id: "ten", emoji: "🔟", title: "Bon début", detail: "10 validations") { $0.totalChecks >= 10 },
        Badge(id: "streak3", emoji: "🔥", title: "Sur la lancée", detail: "Série de 3 jours") { $0.bestStreak >= 3 },
        Badge(id: "streak7", emoji: "📅", title: "Une semaine", detail: "Série de 7 jours") { $0.bestStreak >= 7 },
        Badge(id: "perfect", emoji: "✨", title: "Journée parfaite", detail: "Tout valider en un jour") { $0.perfectDays >= 1 },
        Badge(id: "collector", emoji: "🧺", title: "Collectionneur", detail: "Suivre 5 habitudes") { $0.habitCount >= 5 },
        Badge(id: "level5", emoji: "⭐️", title: "Niveau 5", detail: "Atteindre le niveau 5") { $0.level >= 5 },
        Badge(id: "fifty", emoji: "💪", title: "Assidu", detail: "50 validations") { $0.totalChecks >= 50 },
        Badge(id: "streak30", emoji: "🚀", title: "Inarrêtable", detail: "Série de 30 jours") { $0.bestStreak >= 30 },
        Badge(id: "perfect10", emoji: "💎", title: "Perfectionniste", detail: "10 journées parfaites") { $0.perfectDays >= 10 },
        Badge(id: "hundred", emoji: "💯", title: "Centurion", detail: "100 validations") { $0.totalChecks >= 100 },
        Badge(id: "level10", emoji: "👑", title: "Niveau 10", detail: "Atteindre le niveau 10") { $0.level >= 10 },
    ]
}
