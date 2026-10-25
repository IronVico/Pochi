import SwiftData
import SwiftUI

struct BadgesView: View {
    @Query private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)
        let unlocked = Badge.all.filter { $0.isUnlocked(stats) }.count

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(unlocked) / \(Badge.all.count) débloqués").font(.headline)
                        ProgressView(value: Double(unlocked), total: Double(Badge.all.count))
                            .tint(Theme.accent)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Badge.all) { badge in
                            BadgeCell(badge: badge, unlocked: badge.isUnlocked(stats))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Badges")
        }
    }
}

struct BadgeCell: View {
    let badge: Badge
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(unlocked ? badge.emoji : "🔒")
                .font(.system(size: 36))
                .frame(width: 64, height: 64)
                .background(
                    unlocked ? AnyShapeStyle(Theme.heat.opacity(0.25)) : AnyShapeStyle(Color(.tertiarySystemFill)),
                    in: .circle
                )
            Text(badge.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(badge.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .top)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .opacity(unlocked ? 1 : 0.6)
    }
}
