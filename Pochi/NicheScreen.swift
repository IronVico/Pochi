import SwiftData
import SwiftUI

/// Pochi's doghouse: each level builds a piece of it, each perfect day plants a tree.
struct NicheScreen: View {
    @Query private var habits: [Habit]

    var body: some View {
        let stats = GameStats(habits: habits)
        let care = PochiCare(habits: habits)
        let mood = CorgiMood(stats: stats, care: care)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("La niche")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 60)

                WorldView(level: stats.level, trees: stats.perfectDays, pose: mood.pose, fed: care.food >= 35)
                    .padding(.top, 24)

                NextStepPanel(stats: stats)
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    PixelSprite(grid: PixelIcon.tree, pixel: 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(stats.perfectDays) \(stats.perfectDays > 1 ? "ARBRES" : "ARBRE")")
                            .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        Text("Une journée parfaite = un arbre planté.")
                            .font(Theme.mono(12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .pixelPanel()
                .padding(.top, 12)

                SectionLabel(text: "PLAN DE CONSTRUCTION")
                    .padding(.top, 36)
                    .padding(.bottom, 14)
                VStack(spacing: 8) {
                    ForEach(Construction.steps) { step in
                        BuildStepRow(step: step, built: step.level <= stats.level)
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

/// The isometric world, scaled up pixel-perfect and redrawn ~7 times a second for the
/// little animations. Tapping it pets Pochi.
struct WorldView: View {
    let level: Int
    let trees: Int
    let pose: CorgiPose
    var fed = true
    /// Time of day; nil follows the clock (re-read on every frame, so it changes on its own).
    var phase: IsoWorld.Phase?

    @State private var pettedUntil = Date.distantPast

    private var pochi: IsoWorld.Pochi {
        if pettedUntil > .now { return .happy }
        switch pose {
        case .box, .standing: return .standing
        case .sitting: return .sitting
        case .sleeping: return .sleeping
        case .phone: return .phone
        case .happy: return .happy
        case .sulking: return .sulking
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.14)) { timeline in
            let frame = Int(timeline.date.timeIntervalSinceReferenceDate / 0.14)
            if let image = IsoWorld.render(level: level, trees: trees, pochi: pochi, wander: pettedUntil <= .now, fed: fed,
                                              phase: phase ?? .current, frame: frame) {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(CGFloat(IsoWorld.width) / CGFloat(IsoWorld.height), contentMode: .fit)
            }
        }
        .clipShape(PixelFrame(unit: 4))
        .padding(4)
        .background(PixelFrame(unit: 4).fill(Theme.accent.opacity(0.6)))
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
                    .foregroundStyle(.secondary)
                HStack {
                    Text(next.name.uppercased())
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    Spacer()
                    Text("NIV. \(next.level)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                }
                PixelBlocksBar(filled: Int(stats.progress * 10), total: 10)
                Text("Plus que \(stats.xpNeeded - stats.xpInLevel) XP avant le niveau \(stats.level + 1).")
                    .font(Theme.mono(12))
                    .foregroundStyle(.secondary)
            } else {
                Text("NICHE TERMINÉE")
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                Text("Pochi est logé comme un roi. Continue à planter des arbres.")
                    .font(Theme.mono(12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .pixelPanel(border: Theme.accent.opacity(0.6))
    }
}

struct BuildStepRow: View {
    let step: BuildStep
    let built: Bool

    var body: some View {
        HStack(spacing: 12) {
            PixelSprite(grid: built ? PixelIcon.check : PixelIcon.lock, pixel: 1.5)
            Text(step.name)
                .font(.system(size: 15, weight: built ? .semibold : .regular))
                .foregroundStyle(built ? .primary : .secondary)
            Spacer()
            Text("NIV. \(step.level)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(built ? Theme.accent : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .pixelPanel(border: built ? Theme.accent.opacity(0.4) : Color(white: 0.2))
    }
}

#if DEBUG
/// The four times of day, Pochi's moods, then every construction stage. Launch with `-nicheGallery`.
struct NicheGallery: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(Array(IsoWorld.Phase.allCases.enumerated()), id: \.offset) { _, phase in
                    VStack(spacing: 4) {
                        WorldView(level: 10, trees: 12, pose: .standing, phase: phase)
                        Text("\(phase)".uppercased()).font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
                ForEach(Array([CorgiPose.phone, .sleeping, .sitting, .happy, .sulking].enumerated()), id: \.offset) { _, pose in
                    VStack(spacing: 4) {
                        WorldView(level: 4, trees: 3, pose: pose, phase: .day)
                        Text("\(pose)".uppercased()).font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
                ForEach(1...10, id: \.self) { level in
                    VStack(spacing: 4) {
                        WorldView(level: level, trees: level + 1, pose: .standing)
                        Text("NIV. \(level)").font(Theme.mono(11)).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .padding(.top, 40)
        }
        .background(Color.black)
    }
}
#endif
