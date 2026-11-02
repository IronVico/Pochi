import HealthKit
import SwiftUI

/// What Apple Health says about today. Read-only: Pochi never writes to Health.
struct HealthDay: Equatable {
    var steps = 0
    var exerciseMinutes = 0
    var workouts = 0
    /// Sleep from last night, in hours (overlapping sources merged).
    var sleepHours = 0.0
    var mindfulMinutes = 0
}

/// The link to Apple Health. Not used by the game yet: it only fetches today's numbers.
@MainActor @Observable
final class Health {
    static let shared = Health()
    /// Health never tells an app whether reading was allowed, so remember that we asked.
    static let connectedKey = "healthConnected"

    private let store = HKHealthStore()
    private(set) var today: HealthDay?
    private(set) var isLoading = false

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private(set) var isConnected = UserDefaults.standard.bool(forKey: Health.connectedKey) {
        didSet { UserDefaults.standard.set(isConnected, forKey: Self.connectedKey) }
    }

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.appleExerciseTime),
        HKCategoryType(.sleepAnalysis),
        HKCategoryType(.mindfulSession),
        HKWorkoutType.workoutType(),
    ]

    /// Shows the system permission sheet (only the first time), then reads today.
    func connect() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isConnected = true
            await refresh()
        } catch {
            print("Health authorization failed: \(error)")
        }
    }

    func disconnect() {
        isConnected = false
        today = nil
    }

    func refresh() async {
        guard isAvailable, isConnected else { return }
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date.now
        let morning = calendar.startOfDay(for: now)
        let todayOnly = HKQuery.predicateForSamples(withStart: morning, end: now)
        // Last night: from 18:00 yesterday to noon today.
        let nightStart = calendar.date(byAdding: .hour, value: -6, to: morning)!
        let nightEnd = calendar.date(byAdding: .hour, value: 12, to: morning)!
        let lastNight = HKQuery.predicateForSamples(withStart: nightStart, end: min(now, nightEnd))

        async let steps = sum(.stepCount, unit: .count(), predicate: todayOnly)
        async let exercise = sum(.appleExerciseTime, unit: .minute(), predicate: todayOnly)
        async let workouts = samples(of: HKWorkoutType.workoutType(), predicate: todayOnly)
        async let sleep = samples(of: HKCategoryType(.sleepAnalysis), predicate: lastNight)
        async let mindful = samples(of: HKCategoryType(.mindfulSession), predicate: todayOnly)

        let asleep = HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue)
        let sleepSamples = await sleep.compactMap { $0 as? HKCategorySample }.filter { asleep.contains($0.value) }

        today = HealthDay(
            steps: Int(await steps),
            exerciseMinutes: Int(await exercise),
            workouts: await workouts.count,
            sleepHours: Self.mergedDuration(sleepSamples) / 3600,
            mindfulMinutes: Int(Self.mergedDuration(await mindful) / 60)
        )
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate) async -> Double {
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(id), predicate: predicate),
            options: .cumulativeSum
        )
        let result = try? await descriptor.result(for: store)
        return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    private func samples(of type: HKSampleType, predicate: NSPredicate) async -> [HKSample] {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.sample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        return (try? await descriptor.result(for: store)) ?? []
    }

    /// Total time covered by the samples, counting overlaps once (watch + phone both log sleep).
    private static func mergedDuration(_ samples: [HKSample]) -> TimeInterval {
        var total: TimeInterval = 0
        var current: (start: Date, end: Date)?
        for sample in samples.sorted(by: { $0.startDate < $1.startDate }) {
            if let open = current, sample.startDate <= open.end {
                current = (open.start, max(open.end, sample.endDate))
            } else {
                if let open = current { total += open.end.timeIntervalSince(open.start) }
                current = (sample.startDate, sample.endDate)
            }
        }
        if let open = current { total += open.end.timeIntervalSince(open.start) }
        return total
    }
}
