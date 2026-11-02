import SwiftData
import SwiftUI

/// Pochi's doghouse: each level builds a piece of it, each perfect day plants a tree.
struct NicheScreen: View {
    @Query private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)
        let care = PochiCare(habits: habits, health: Health.shared.today)
        let mood = CorgiMood(stats: stats, care: care)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("La niche")
                    .font(Theme.title(46))
                    .tracking(-1)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 60)

                WorldView(level: stats.level, trees: stats.perfectDays, pose: mood.pose, fed: care.food >= 35)
                    .padding(.top, 24)

                NextStepPanel(stats: stats)
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    Doodle(symbol: "tree", fill: Theme.mint, size: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(stats.perfectDays) \(stats.perfectDays > 1 ? "ARBRES" : "ARBRE")")
                            .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        Text("Une journée parfaite = un arbre planté.")
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                    Spacer()
                }
                .foregroundStyle(Theme.ink)
                .padding(16)
                .sketchCard(fill: Theme.mint.opacity(0.5))
                .padding(.top, 12)

                Text("Ce qu'on bâtit")
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 36)
                    .padding(.bottom, 16)
                VStack(spacing: 10) {
                    ForEach(Construction.steps) { step in
                        BuildStepRow(step: step, built: step.level <= stats.level)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(DottedPaper())
    }
}

/// The illustrated niche (see NicheScene), with Pochi in the yard. Tapping it pets Pochi.
struct WorldView: View {
    let level: Int
    let trees: Int
    let pose: CorgiPose
    var fed = true
    /// Time of day; nil follows the clock (re-read on every frame, so it changes on its own).
    var phase: TimeOfDay?

    @State private var pettedUntil = Date.distantPast

    private var pochi: CorgiPose {
        if pettedUntil > .now { return .happy }
        return pose == .box ? .sitting : pose
    }

    var body: some View {
        let size = NicheScene.size
        GeometryReader { geo in
            let scale = geo.size.width / size.width
            TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, _ in
                    ctx.scaleBy(x: scale, y: scale)
                    NicheScene(level: level, trees: trees, fed: fed, time: phase ?? .current, t: t).draw(in: ctx)
                }
            }
            // Pochi trots a little around its spot, unless it is lying down.
            let pochiHeight = 50 * scale
            let still = [.sleeping, .sulking, .phone, .blanket, .basket, .bowl].contains(pochi)
            PhaseAnimator([-1.0, 1.0]) { side in
                PochiView(pose: pochi, size: pochiHeight)
                    .offset(x: still ? 0 : side * 10 * scale)
            } animation: { _ in .easeInOut(duration: 2.4) }
            .position(x: NicheScene.pochiSpot.x * scale, y: NicheScene.pochiSpot.y * scale - pochiHeight / 2)
            .allowsHitTesting(false)
        }
        .aspectRatio(size.width / size.height, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.line, lineWidth: Theme.outline) }
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.coral).offset(Theme.lift))
        .padding(.trailing, Theme.lift.width)
        .padding(.bottom, Theme.lift.height)
        .contentShape(.rect)
        .onTapGesture {
            pettedUntil = .now.addingTimeInterval(1.5)
            Feedback.pet()
        }
    }
}

struct NextStepPanel: View {
    let stats: GameStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let next = Construction.next(after: stats.level) {
                Text("PROCHAINE ÉTAPE")
                    .font(Theme.mono(11))
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                HStack {
                    Text(next.name.uppercased())
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    Spacer()
                    Text("NIV. \(next.level)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                }
                BlocksBar(filled: Int(stats.progress * 10), total: 10)
                Text("Plus que \(stats.xpNeeded - stats.xpInLevel) XP avant le niveau \(stats.level + 1).")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            } else {
                Text("NICHE TERMINÉE")
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                Text("Pochi est logé comme un roi. Continue à planter des arbres.")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(18)
        .sketchCard()
    }
}

struct BuildStepRow: View {
    let step: BuildStep
    let built: Bool

    var body: some View {
        HStack(spacing: 12) {
            Doodle(symbol: built ? "checkmark.circle" : "lock", fill: built ? Theme.mint : Theme.paper, size: 17)
            Text(step.name)
                .font(.system(size: 15, weight: built ? .semibold : .regular))
                .foregroundStyle(Theme.ink.opacity(built ? 1 : 0.5))
            Spacer()
            Text("NIV. \(step.level)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.ink.opacity(built ? 1 : 0.45))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .sketchCard(fill: built ? Theme.card : Theme.paper, shadow: built ? Theme.mint : Theme.line.opacity(0.15), radius: 14)
    }
}

#if DEBUG
/// The four times of day, Pochi's moods, then every construction stage. Launch with `-nicheGallery`.
struct NicheGallery: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(TimeOfDay.allCases, id: \.self) { phase in
                    VStack(spacing: 4) {
                        WorldView(level: 10, trees: 12, pose: .sitting, phase: phase)
                        Text("\(phase)".uppercased()).font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
                ForEach([CorgiPose.phone, .blanket, .sleeping, .basket, .sitting, .bowl, .scarf, .ball, .happy, .sulking], id: \.self) { pose in
                    VStack(spacing: 4) {
                        WorldView(level: 4, trees: 3, pose: pose, phase: .day)
                        Text("\(pose)".uppercased()).font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
                ForEach(1...10, id: \.self) { level in
                    VStack(spacing: 4) {
                        WorldView(level: level, trees: level + 1, pose: .sitting)
                        Text("NIV. \(level)").font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .padding(.top, 40)
        }
        .background(DottedPaper())
    }
}
#endif
