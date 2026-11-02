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

/// What each level adds to Pochi's doghouse (see NicheScene).
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

/// Pochi's needs, Tamagotchi-style. Computed by replaying the recent history day by day,
/// so nothing extra is stored: every gauge drops on its own and your habits fill it back up.
struct PochiCare {
    /// Filled by every check-in, drops fastest.
    var food = 70.0
    /// Filled by finishing your day (bonus for a perfect day).
    var happiness = 70.0
    /// Filled by showing up: at least one check-in in the day.
    var energy = 70.0

    var health: Double { (food + happiness + energy) / 3 }
    /// Below this, Pochi sulks.
    static let sulkThreshold = 30.0

    /// `health` is today's Apple Health data, when connected: it nudges today's energy.
    init(habits: [Habit], health: HealthDay? = nil, now: Date = .now) {
        guard let created = habits.map(\.createdAt).min() else { return }
        let calendar = Day.calendar
        let today = calendar.startOfDay(for: now)
        // A month of history is plenty: older days no longer show in the gauges.
        var day = max(calendar.startOfDay(for: created), Day.offset(-30, from: today))
        let todayKey = Day.key(now)

        while true {
            let key = Day.key(day)
            let isToday = key == todayKey
            // Today only counts the part of the day already gone: gauges drop through the day.
            let elapsed = isToday ? now.timeIntervalSince(today) / 86_400 : 1
            let active = habits.filter { Day.key($0.createdAt) <= key }
            let done = active.filter { $0.isDone(key) }.count
            let ratio = active.isEmpty ? 0 : Double(done) / Double(active.count)

            food = Self.clamp(food - 40 * elapsed + 18 * Double(done))
            energy = Self.clamp(energy - 22 * elapsed + (done > 0 ? 25 : 0))
            happiness = Self.clamp(happiness - 25 * elapsed + 45 * ratio + (ratio == 1 ? 15 : 0))

            if isToday || key > todayKey { break }
            day = Day.offset(1, from: day)
        }

        if let health { energy = Self.clamp(energy + Self.energyBonus(health)) }
    }

    /// Slept well: +15, slept under 6 h: −10, active day (8,000 steps or a workout): +10.
    /// No sleep data counts as neither.
    static func energyBonus(_ health: HealthDay) -> Double {
        var bonus = 0.0
        if health.sleepHours >= 7 {
            bonus += 15
        } else if health.sleepHours > 0, health.sleepHours < 6 {
            bonus -= 10
        }
        if health.steps >= 8000 || health.workouts > 0 { bonus += 10 }
        return bonus
    }

    private static func clamp(_ value: Double) -> Double { min(max(value, 0), 100) }
}
