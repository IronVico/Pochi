import Foundation
import SwiftData
import SwiftUI

// MARK: - Days

/// Days are stored as "yyyy-MM-dd" keys so they sort and compare as plain strings.
enum Day {
    static let calendar = Calendar.current

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ date: Date = .now) -> String { formatter.string(from: date) }
    static func date(_ key: String) -> Date? { formatter.date(from: key) }
    static func offset(_ days: Int, from date: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }
}

// MARK: - Habit

@Model
final class Habit {
    var name: String
    var emoji: String
    var colorName: String
    var createdAt: Date
    var order: Int
    var completedDays: [String]
    /// Apple Health data that checks this habit by itself (`HealthMetric` raw value), if any.
    var healthMetric: String? = nil
    /// Value to reach in `healthMetric`, in its unit.
    var healthGoal: Double = 0

    init(name: String, emoji: String, colorName: String, order: Int) {
        self.name = name
        self.emoji = emoji
        self.colorName = colorName
        self.order = order
        self.createdAt = .now
        self.completedDays = []
    }

    var color: Color { HabitColor.color(colorName) }

    var metric: HealthMetric? { healthMetric.flatMap(HealthMetric.init(rawValue:)) }

    /// True when today's Health data reaches the goal.
    func reachedGoal(in day: HealthDay?) -> Bool {
        guard let metric, let day, healthGoal > 0 else { return false }
        return metric.value(in: day) >= healthGoal
    }

    func isDone(_ key: String = Day.key()) -> Bool { completedDays.contains(key) }

    func toggle(_ key: String = Day.key()) {
        if let i = completedDays.firstIndex(of: key) {
            completedDays.remove(at: i)
        } else {
            completedDays.append(key)
        }
    }

    /// Streak ending today, or yesterday if today isn't checked yet (so it isn't "lost" until tomorrow).
    var currentStreak: Int {
        let done = Set(completedDays)
        var day = Date.now
        if !done.contains(Day.key(day)) { day = Day.offset(-1, from: day) }
        var count = 0
        while done.contains(Day.key(day)) {
            count += 1
            day = Day.offset(-1, from: day)
        }
        return count
    }

    /// Length of the streak at each completion, in chronological order.
    var streakRuns: [Int] {
        var runs: [Int] = []
        var previous: Date?
        var run = 0
        for key in Set(completedDays).sorted() {
            guard let date = Day.date(key) else { continue }
            if let previous, Day.key(Day.offset(1, from: previous)) == key {
                run += 1
            } else {
                run = 1
            }
            runs.append(run)
            previous = date
        }
        return runs
    }

    var bestStreak: Int { streakRuns.max() ?? 0 }

    var xp: Int { streakRuns.reduce(0) { $0 + Game.xp(forRun: $1) } }

    /// XP you'd earn by checking it today.
    var nextXP: Int { Game.xp(forRun: currentStreak + 1) }
}

// MARK: - Colors

enum HabitColor {
    static let all: [(name: String, color: Color)] = [
        ("orange", Color(hex: 0xF5A55B)), ("pink", Theme.pink), ("purple", Color(hex: 0xB89AEB)),
        ("indigo", Theme.periwinkle), ("blue", Color(hex: 0x86C3F2)), ("teal", Color(hex: 0x7ED6CB)),
        ("green", Theme.mint), ("red", Theme.coral),
    ]

    static func color(_ name: String) -> Color {
        all.first { $0.name == name }?.color ?? Theme.coral
    }
}
