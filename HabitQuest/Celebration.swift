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
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                PixelCorgi(pose: .happy, pixel: 5)
                    .scaleEffect(pop ? 1 : 0.3)
                    .padding(.top, 10)
                Text("NIVEAU SUPÉRIEUR")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.secondary)
                Text("NIVEAU \(level)")
                    .font(.system(size: 40, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.heat)
                Text(Game.title(forLevel: level))
                    .font(.title3.weight(.semibold))
                Button("CONTINUER", action: onDismiss)
                    .buttonStyle(PixelButtonStyle())
                    .padding(.top, 10)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .pixelPanel(fill: Color(white: 0.09), border: Theme.accent, unit: 4)
            .scaleEffect(pop ? 1 : 0.85)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.05)) { pop = true }
        }
    }
}
