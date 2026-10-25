import SwiftUI

/// Bursts confetti from the top of the screen every time `trigger` changes.
struct ConfettiView: View {
    let trigger: Int

    private struct Particle {
        let x: Double
        let vx: Double
        let vy: Double
        let size: Double
        let spin: Double
        let color: Color
    }

    private static let duration = 3.0
    private static let colors: [Color] = [.purple, .pink, .orange, .yellow, .green, .blue, .teal]

    @State private var start: Date?
    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: start == nil)) { timeline in
            Canvas { ctx, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                let fade = max(0, 1 - max(0, t - Self.duration + 0.8) / 0.8)
                ctx.opacity = fade
                for p in particles {
                    var c = ctx
                    let x = p.x * size.width + p.vx * t
                    let y = -20 + p.vy * t + 0.5 * 420 * t * t
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(p.spin * t))
                    c.fill(
                        Path(roundedRect: CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2), cornerRadius: 1.5),
                        with: .color(p.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: trigger) {
            particles = (0..<140).map { _ in
                Particle(
                    x: .random(in: 0...1),
                    vx: .random(in: -60...60),
                    vy: .random(in: 20...260),
                    size: .random(in: 7...13),
                    spin: .random(in: -8...8),
                    color: Self.colors.randomElement()!
                )
            }
            let thisStart = Date.now
            start = thisStart
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) {
                if start == thisStart { start = nil }
            }
        }
    }
}

struct LevelUpView: View {
    let level: Int
    let onDismiss: () -> Void

    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                Text("🎉").font(.system(size: 70))
                    .scaleEffect(pop ? 1 : 0.3)
                    .rotationEffect(.degrees(pop ? 0 : -30))
                Text("NIVEAU SUPÉRIEUR").font(.caption.bold()).tracking(2).foregroundStyle(.secondary)
                Text("Niveau \(level)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.heat)
                Text(Game.title(forLevel: level)).font(.title3.weight(.semibold))
                Button(action: onDismiss) {
                    Text("Continuer")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.heat, in: .capsule)
                }
                .padding(.top, 8)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: .rect(cornerRadius: 30))
            .sensoryFeedback(.success, trigger: pop)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) { pop = true }
        }
    }
}
