import SwiftData
import SwiftUI

struct BadgesView: View {
    @Query private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)
        let unlocked = Badge.all.filter { $0.isUnlocked(stats) }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Badges")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 60)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        PixelSprite(grid: PixelIcon.trophy, pixel: 2)
                        Text("\(unlocked) / \(Badge.all.count) DÉBLOQUÉS")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    }
                    PixelBlocksBar(filled: unlocked, total: Badge.all.count)
                }
                .padding(18)
                .pixelPanel(border: Theme.accent.opacity(0.6))
                .padding(.top, 24)

                SectionLabel(text: "COLLECTION")
                    .padding(.top, 36)
                    .padding(.bottom, 14)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(Badge.all) { badge in
                        BadgeCell(badge: badge, unlocked: badge.isUnlocked(stats))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }
}

struct BadgeCell: View {
    let badge: Badge
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if unlocked {
                    PixelFrame(unit: 4).fill(Theme.heat)
                    PixelFrame(unit: 4).fill(Color(white: 0.11)).padding(4)
                    Text(badge.emoji).font(.system(size: 30))
                } else {
                    PixelFrame(unit: 4).fill(Color(white: 0.16))
                    PixelSprite(grid: PixelIcon.lock, pixel: 2.5)
                }
            }
            .frame(width: 62, height: 62)

            Text(badge.title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
            Text(badge.detail)
                .font(Theme.mono(9))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .pixelPanel(border: unlocked ? Theme.accent.opacity(0.6) : Color(white: 0.2))
        .opacity(unlocked ? 1 : 0.55)
    }
}
