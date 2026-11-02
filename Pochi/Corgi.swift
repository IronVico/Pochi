import SwiftUI

// MARK: - Pochi

/// Pochi's pose, which follows your day.
enum CorgiPose {
    case box, sleeping, phone, sitting, happy
    /// Rolled up in a plaid, only the head and paws sticking out.
    case blanket
    /// Sitting with a tennis ball between its paws.
    case ball
    /// Munching from its bowl.
    case bowl
    /// Sitting in a beanie and scarf, for winter.
    case scarf
    /// Asleep in a wicker basket.
    case basket
    /// Neglected: lying down, sulking under a little rain cloud.
    case sulking
}

/// Pochi drawn as a sketchbook doodle: a front-facing corgi with ink outlines,
/// on a 120 × 100 canvas. Tail wag, breathing and blinks are animated; tap it and
/// it gets happy for a moment.
struct PochiView: View {
    let pose: CorgiPose
    /// Height on screen; the width is 1.2 times that.
    var size: CGFloat = 92
    var onTap: () -> Void = {}

    @State private var blink = false
    @State private var excitedUntil = Date.distantPast

    private var excited: Bool { pose == .happy || excitedUntil > .now }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let hop = excited && pose != .box ? abs(sin(t * 9)) * 4 : 0
            Canvas { ctx, canvas in
                ctx.scaleBy(x: canvas.width / 120, y: canvas.height / 100)
                CorgiDrawing(pose: pose, time: t, excited: excited, blink: blink).draw(in: ctx)
            }
            .offset(y: -hop * size / 100)
        }
        .frame(width: size * 1.2, height: size)
        .overlay(alignment: .topLeading) {
            let s = size / 100
            switch pose {
            case .sleeping: Zzz(size: size).offset(x: 78 * s, y: 18 * s)
            case .basket: Zzz(size: size).offset(x: 80 * s, y: 14 * s)
            case .sulking: RainCloud(size: size).offset(x: 18 * s, y: -6 * s)
            case .happy: Hearts(size: size).offset(x: 54 * s, y: 4 * s)
            default: EmptyView()
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            excitedUntil = .now.addingTimeInterval(1.5)
            Feedback.pet()
            onTap()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(.random(in: 3...5)))
                blink = true
                try? await Task.sleep(for: .milliseconds(140))
                blink = false
            }
        }
    }
}

/// The drawing itself. Coordinates are in the 120 × 100 canvas; the head is drawn
/// around (60, 40) and moved into place, the right half of the face mirrors the left.
private struct CorgiDrawing {
    let pose: CorgiPose
    let time: Double
    let excited: Bool
    let blink: Bool

    static let fur = Color(hex: 0xF0A04B)
    static let tennis = Color(hex: 0xD8E85A)
    static let kibble = Color(hex: 0xA8642B)
    static let wicker = Color(hex: 0xD49A5C)
    static let wickerShadow = Color(hex: 0xA8703C)
    static let cream = Color(hex: 0xFFFBF2)
    static let blush = Color(hex: 0xF4A3A3)
    static let cardboard = Color(hex: 0xDDA867)
    static let screen = Color(hex: 0xBFE3FF)

    private enum Eyes { case open, closed, happy, half, sad }

    private var eyes: Eyes {
        switch pose {
        case .sleeping, .basket: .closed
        case .happy, .bowl: .happy
        case .phone: .half
        case .sulking: .sad
        default: blink ? .closed : (excited ? .happy : .open)
        }
    }

    private var lying: Bool { pose == .sleeping || pose == .sulking }

    func draw(in ctx: GraphicsContext) {
        let wag = excited || pose == .ball ? sin(time * 18) * 0.5 : sin(time * 2.5) * 0.18
        switch pose {
        case .box:
            let peek = (sin(time * 1.6) + 1) * 3
            backFlaps(ctx)
            head(ctx, center: CGPoint(x: 60, y: 46 + peek))
            box(ctx)
            paw(ctx, CGPoint(x: 47, y: 64), rx: 7, ry: 4.5)
            paw(ctx, CGPoint(x: 73, y: 64), rx: 7, ry: 4.5)
        case .sleeping, .sulking:
            let breath = pose == .sleeping ? sin(time * 2) * 1.2 : 0
            tail(ctx, base: CGPoint(x: 98, y: 82), angle: pose == .sleeping ? 0.3 : 0.9)
            outlined(ctx, oval(66, 84 - breath / 2, 40, 13 + breath / 2), Self.fur)
            head(ctx, center: CGPoint(x: 44, y: 62), tilt: pose == .sleeping ? -0.12 : 0.06)
            paw(ctx, CGPoint(x: 30, y: 92), rx: 9, ry: 5)
            paw(ctx, CGPoint(x: 52, y: 93), rx: 9, ry: 5)
        case .bowl:
            let chew = abs(sin(time * 7)) * 1.5
            tail(ctx, base: CGPoint(x: 84, y: 74), angle: -0.5 + wag)
            outlined(ctx, oval(60, 75, 29, 21), Self.fur)
            ctx.fill(oval(60, 77, 15, 15), with: .color(Self.cream))
            head(ctx, center: CGPoint(x: 60, y: 45 + chew))
            bowl(ctx)
            paw(ctx, CGPoint(x: 36, y: 94), rx: 8, ry: 5)
            paw(ctx, CGPoint(x: 84, y: 94), rx: 8, ry: 5)
        case .basket:
            let breath = sin(time * 2) * 0.8
            ctx.fill(oval(60, 66, 42, 9), with: .color(Self.wickerShadow))
            tail(ctx, base: CGPoint(x: 88, y: 64), angle: -0.4)
            head(ctx, center: CGPoint(x: 56, y: 45 + breath), tilt: -0.12)
            basket(ctx)
            paw(ctx, CGPoint(x: 44, y: 64), rx: 7, ry: 4.5)
            paw(ctx, CGPoint(x: 62, y: 65), rx: 7, ry: 4.5)
        case .blanket:
            let breath = sin(time * 2) * 0.8
            head(ctx, center: CGPoint(x: 60, y: 39 - breath), tilt: excited ? sin(time * 9) * 0.06 : 0)
            blanket(ctx)
            paw(ctx, CGPoint(x: 46, y: 68), rx: 6, ry: 4.5)
            paw(ctx, CGPoint(x: 74, y: 68), rx: 6, ry: 4.5)
        default:
            tail(ctx, base: CGPoint(x: 84, y: 74), angle: -0.5 + wag)
            outlined(ctx, oval(60, 75, 29, 21), Self.fur)
            ctx.fill(oval(60, 77, 15, 15), with: .color(Self.cream))
            if pose == .phone {
                head(ctx, center: CGPoint(x: 60, y: 40), tilt: 0.05)
                phone(ctx)
                paw(ctx, CGPoint(x: 48, y: 80), rx: 6, ry: 5)
                paw(ctx, CGPoint(x: 72, y: 80), rx: 6, ry: 5)
            } else if pose == .ball {
                head(ctx, center: CGPoint(x: 60, y: 40), tilt: -0.08 + (excited ? sin(time * 9) * 0.06 : 0))
                ball(ctx)
                paw(ctx, CGPoint(x: 47, y: 80), rx: 5, ry: 6)
                paw(ctx, CGPoint(x: 73, y: 80), rx: 5, ry: 6)
            } else if pose == .scarf {
                head(ctx, center: CGPoint(x: 60, y: 40))
                winterGear(ctx)
            } else {
                head(ctx, center: CGPoint(x: 60, y: 40), tilt: excited ? sin(time * 9) * 0.06 : 0)
            }
            paw(ctx, CGPoint(x: 48, y: 94), rx: 8, ry: 5)
            paw(ctx, CGPoint(x: 72, y: 94), rx: 8, ry: 5)
        }
    }

    // MARK: Parts

    private func head(_ ctx: GraphicsContext, center: CGPoint, tilt: Double = 0) {
        var ctx = ctx
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: .radians(tilt))
        ctx.translateBy(x: -60, y: -40)

        mirrored(ctx) { ear($0) }
        outlined(ctx, oval(60, 40, 31, 25), Self.fur)
        // Markings: a blaze down the forehead and a white muzzle.
        ctx.fill(oval(60, 29, 4.5, 12), with: .color(Self.cream))
        ctx.fill(oval(60, 50, 15, 10.5), with: .color(Self.cream))
        mirrored(ctx) { side in
            side.fill(oval(41, 50, 5, 3), with: .color(Self.blush.opacity(0.6)))
            eye(side)
        }
        let tongue = excited || pose == .happy
        if tongue { outlined(ctx, oval(60, 56.5, 3.4, 4), Self.blush, width: 2) }
        ctx.fill(oval(60, 46.5, 4.2, 3), with: .color(Theme.darkInk))
        var mouth = Path()
        mouth.move(to: CGPoint(x: 60, y: 49))
        mouth.addLine(to: CGPoint(x: 60, y: 52))
        if pose == .sulking {
            mouth.move(to: CGPoint(x: 55.5, y: 54.5))
            mouth.addQuadCurve(to: CGPoint(x: 64.5, y: 54.5), control: CGPoint(x: 60, y: 50.5))
        } else {
            mouth.addQuadCurve(to: CGPoint(x: 55, y: 52.5), control: CGPoint(x: 57.5, y: 55.5))
            mouth.move(to: CGPoint(x: 60, y: 52))
            mouth.addQuadCurve(to: CGPoint(x: 65, y: 52.5), control: CGPoint(x: 62.5, y: 55.5))
        }
        ctx.stroke(mouth, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    /// Left ear; it droops outward when Pochi sulks.
    private func ear(_ ctx: GraphicsContext) {
        var ctx = ctx
        if pose == .sulking {
            ctx.translateBy(x: 40, y: 26)
            ctx.rotate(by: .radians(-0.55))
            ctx.translateBy(x: -40, y: -26)
        }
        var outer = Path()
        outer.move(to: CGPoint(x: 30, y: 33))
        outer.addQuadCurve(to: CGPoint(x: 35, y: 3), control: CGPoint(x: 26, y: 12))
        outer.addQuadCurve(to: CGPoint(x: 52, y: 20), control: CGPoint(x: 46, y: 6))
        outer.closeSubpath()
        outlined(ctx, outer, Self.fur)
        var inner = Path()
        inner.move(to: CGPoint(x: 34, y: 27))
        inner.addQuadCurve(to: CGPoint(x: 36.5, y: 10), control: CGPoint(x: 32, y: 15))
        inner.addQuadCurve(to: CGPoint(x: 46, y: 20), control: CGPoint(x: 43, y: 12))
        inner.closeSubpath()
        ctx.fill(inner, with: .color(Self.blush))
    }

    /// Left eye.
    private func eye(_ ctx: GraphicsContext) {
        let x = 47.0, y = 40.0
        let ink = GraphicsContext.Shading.color(Theme.darkInk)
        let line = StrokeStyle(lineWidth: 2.4, lineCap: .round)
        switch eyes {
        case .open:
            ctx.fill(oval(x, y, 3.6, 3.8), with: ink)
            ctx.fill(oval(x + 1.1, y - 1.3, 1.1, 1.1), with: .color(.white))
        case .closed:
            var arc = Path()
            arc.move(to: CGPoint(x: x - 4, y: y))
            arc.addQuadCurve(to: CGPoint(x: x + 4, y: y), control: CGPoint(x: x, y: y + 3.5))
            ctx.stroke(arc, with: ink, style: line)
        case .happy:
            var arc = Path()
            arc.move(to: CGPoint(x: x - 4, y: y + 1.5))
            arc.addQuadCurve(to: CGPoint(x: x + 4, y: y + 1.5), control: CGPoint(x: x, y: y - 4.5))
            ctx.stroke(arc, with: ink, style: line)
        case .half:
            var lid = Path()
            lid.addArc(center: CGPoint(x: x, y: y + 1), radius: 3.6, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            lid.closeSubpath()
            ctx.fill(lid, with: ink)
            var brow = Path()
            brow.move(to: CGPoint(x: x - 4.5, y: y + 1))
            brow.addLine(to: CGPoint(x: x + 4.5, y: y + 1))
            ctx.stroke(brow, with: ink, style: line)
        case .sad:
            ctx.fill(oval(x, y + 2, 3.2, 3.4), with: ink)
            ctx.fill(oval(x + 0.9, y + 0.9, 1, 1), with: .color(.white))
            var brow = Path()
            brow.move(to: CGPoint(x: x - 5, y: y - 3.5))
            brow.addLine(to: CGPoint(x: x + 4, y: y - 6.5))
            ctx.stroke(brow, with: ink, style: line)
        }
    }

    private func tail(_ ctx: GraphicsContext, base: CGPoint, angle: Double) {
        var ctx = ctx
        ctx.translateBy(x: base.x, y: base.y)
        ctx.rotate(by: .radians(angle))
        outlined(ctx, oval(9, 0, 11, 6.5), Self.fur)
        ctx.fill(oval(16, 0, 4, 3.5), with: .color(Self.cream))
    }

    /// A coral plaid wrapped up to the chin.
    private func blanket(_ ctx: GraphicsContext) {
        var shape = Path()
        shape.move(to: CGPoint(x: 22, y: 98))
        shape.addQuadCurve(to: CGPoint(x: 32, y: 68), control: CGPoint(x: 20, y: 76))
        shape.addQuadCurve(to: CGPoint(x: 88, y: 68), control: CGPoint(x: 60, y: 60))
        shape.addQuadCurve(to: CGPoint(x: 98, y: 98), control: CGPoint(x: 100, y: 76))
        shape.closeSubpath()
        ctx.fill(shape, with: .color(Theme.coral))
        var stripes = ctx
        stripes.clip(to: shape)
        var lines = Path()
        for x in stride(from: 32.0, through: 88, by: 14) {
            lines.move(to: CGPoint(x: x, y: 50))
            lines.addLine(to: CGPoint(x: x, y: 100))
        }
        for y in stride(from: 72.0, through: 96, by: 12) {
            lines.move(to: CGPoint(x: 10, y: y))
            lines.addLine(to: CGPoint(x: 110, y: y))
        }
        stripes.stroke(lines, with: .color(.white.opacity(0.4)), lineWidth: 3)
        ctx.stroke(shape, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
    }

    /// A periwinkle bowl heaped with kibble.
    private func bowl(_ ctx: GraphicsContext) {
        for (x, y) in [(47.0, 81.0), (54.0, 78.5), (61.0, 79.5), (68.0, 78.5), (73.0, 81.0), (57.0, 81.5)] {
            outlined(ctx, oval(x, y, 3.4, 3), Self.kibble, width: 1.5)
        }
        var dish = Path()
        dish.move(to: CGPoint(x: 38, y: 82))
        dish.addLine(to: CGPoint(x: 82, y: 82))
        dish.addQuadCurve(to: CGPoint(x: 75, y: 98), control: CGPoint(x: 82, y: 96))
        dish.addLine(to: CGPoint(x: 45, y: 98))
        dish.addQuadCurve(to: CGPoint(x: 38, y: 82), control: CGPoint(x: 38, y: 96))
        dish.closeSubpath()
        outlined(ctx, dish, Theme.periwinkle)
        ctx.draw(Text("POCHI").font(.system(size: 6, weight: .heavy)).foregroundStyle(.white), at: CGPoint(x: 60, y: 90))
    }

    /// A coral beanie with a pompom, and a matching scarf with a loose end.
    private func winterGear(_ ctx: GraphicsContext) {
        var beanie = Path()
        beanie.move(to: CGPoint(x: 36, y: 30))
        beanie.addQuadCurve(to: CGPoint(x: 84, y: 30), control: CGPoint(x: 60, y: 2))
        beanie.closeSubpath()
        outlined(ctx, beanie, Theme.coral)
        outlined(ctx, Path(roundedRect: CGRect(x: 33, y: 26, width: 54, height: 9), cornerRadius: 4.5), Self.cream)
        outlined(ctx, oval(60, 11, 5, 5), Self.cream)

        let end = Path(roundedRect: CGRect(x: 66, y: 63, width: 9, height: 22), cornerRadius: 3)
        outlined(ctx, end, Theme.coral)
        outlined(ctx, Path(roundedRect: CGRect(x: 38, y: 59, width: 44, height: 10), cornerRadius: 5), Theme.coral)
        var stripes = Path()
        for y in [74.0, 79.0] {
            stripes.move(to: CGPoint(x: 67.5, y: y))
            stripes.addLine(to: CGPoint(x: 73.5, y: y))
        }
        ctx.stroke(stripes, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    /// The front of a wicker basket, with its rim.
    private func basket(_ ctx: GraphicsContext) {
        var front = Path()
        front.move(to: CGPoint(x: 20, y: 66))
        front.addLine(to: CGPoint(x: 100, y: 66))
        front.addQuadCurve(to: CGPoint(x: 86, y: 98), control: CGPoint(x: 100, y: 92))
        front.addLine(to: CGPoint(x: 34, y: 98))
        front.addQuadCurve(to: CGPoint(x: 20, y: 66), control: CGPoint(x: 20, y: 92))
        front.closeSubpath()
        ctx.fill(front, with: .color(Self.wicker))
        var weave = ctx
        weave.clip(to: front)
        var lines = Path()
        for (row, y) in [76.0, 84.0, 92.0].enumerated() {
            lines.move(to: CGPoint(x: 10, y: y))
            lines.addLine(to: CGPoint(x: 110, y: y))
            for x in stride(from: 24.0 + Double(row % 2) * 6, through: 100, by: 12) {
                lines.move(to: CGPoint(x: x, y: y - 6))
                lines.addLine(to: CGPoint(x: x, y: y - 2))
            }
        }
        weave.stroke(lines, with: .color(Self.wickerShadow), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        ctx.stroke(front, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
        outlined(ctx, Path(roundedRect: CGRect(x: 15, y: 61, width: 90, height: 9), cornerRadius: 4.5), Self.wicker)
    }

    private func ball(_ ctx: GraphicsContext) {
        outlined(ctx, oval(60, 81, 12, 12), Self.tennis)
        var seam = Path()
        seam.move(to: CGPoint(x: 53, y: 72))
        seam.addQuadCurve(to: CGPoint(x: 53, y: 90), control: CGPoint(x: 60, y: 81))
        seam.move(to: CGPoint(x: 67, y: 72))
        seam.addQuadCurve(to: CGPoint(x: 67, y: 90), control: CGPoint(x: 60, y: 81))
        ctx.stroke(seam, with: .color(.white), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func paw(_ ctx: GraphicsContext, _ at: CGPoint, rx: Double, ry: Double) {
        outlined(ctx, oval(at.x, at.y, rx, ry), Self.cream, width: 2.2)
    }

    private func phone(_ ctx: GraphicsContext) {
        let body = Path(roundedRect: CGRect(x: 50, y: 62, width: 20, height: 28), cornerRadius: 4)
        outlined(ctx, body, Theme.darkInk)
        let screenRect = CGRect(x: 52.5, y: 65, width: 15, height: 22)
        ctx.fill(Path(roundedRect: screenRect, cornerRadius: 2), with: .color(Self.screen))
        // Lines scrolling up the screen.
        let scroll = (time * 6).truncatingRemainder(dividingBy: 5)
        var lines = Path()
        for i in 0..<5 {
            let y = screenRect.maxY - 3 - (Double(i) * 5 + scroll).truncatingRemainder(dividingBy: 20)
            lines.move(to: CGPoint(x: 55, y: y))
            lines.addLine(to: CGPoint(x: i % 2 == 0 ? 65 : 61, y: y))
        }
        ctx.stroke(lines, with: .color(Theme.periwinkle), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }

    private func backFlaps(_ ctx: GraphicsContext) {
        mirrored(ctx) { side in
            var flap = Path()
            flap.addLines([CGPoint(x: 22, y: 64), CGPoint(x: 8, y: 44), CGPoint(x: 32, y: 46), CGPoint(x: 40, y: 64)])
            flap.closeSubpath()
            outlined(side, flap, Self.cardboard.opacity(0.85))
        }
    }

    private func box(_ ctx: GraphicsContext) {
        outlined(ctx, Path(roundedRect: CGRect(x: 18, y: 63, width: 84, height: 36), cornerRadius: 3), Self.cardboard)
        var tape = Path()
        tape.move(to: CGPoint(x: 60, y: 64))
        tape.addLine(to: CGPoint(x: 60, y: 74))
        ctx.stroke(tape, with: .color(Theme.darkInk.opacity(0.35)), lineWidth: 2)
        ctx.draw(Text("FRAGILE").font(.system(size: 7, weight: .heavy)).foregroundStyle(Theme.darkInk.opacity(0.45)),
                 at: CGPoint(x: 60, y: 86))
    }

    // MARK: Helpers

    private func oval(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    private func outlined(_ ctx: GraphicsContext, _ path: Path, _ fill: Color, width: Double = 2.6) {
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: width, lineJoin: .round))
    }

    /// Draws `part` as given, then mirrored across the middle of the canvas.
    private func mirrored(_ ctx: GraphicsContext, _ part: (GraphicsContext) -> Void) {
        part(ctx)
        var flipped = ctx
        flipped.translateBy(x: 120, y: 0)
        flipped.scaleBy(x: -1, y: 1)
        part(flipped)
    }
}

// MARK: - Mood effects

private struct Zzz: View {
    let size: CGFloat

    var body: some View {
        PhaseAnimator([0, 1, 2]) { phase in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<3) { i in
                    Text("z")
                        .font(Theme.hand(size * (0.12 + CGFloat(i) * 0.05)))
                        .opacity(i <= phase ? 0.9 : 0)
                        .offset(y: CGFloat(-i) * size * 0.07)
                }
            }
            .foregroundStyle(Theme.periwinkle)
        } animation: { _ in .easeInOut(duration: 0.6) }
    }
}

/// A small grey cloud with rain falling, over a sulking Pochi.
private struct RainCloud: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, canvas in
                ctx.scaleBy(x: canvas.width / 40, y: canvas.height / 34)
                var cloud = Path(roundedRect: CGRect(x: 4, y: 9, width: 32, height: 9), cornerRadius: 4.5)
                for (x, y, r) in [(13.0, 9.0, 6.0), (23.0, 7.0, 7.5), (31.0, 11.0, 4.5)] {
                    cloud = cloud.union(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)))
                }
                ctx.fill(cloud, with: .color(Color(hex: 0xD6DAE2)))
                ctx.stroke(cloud, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                var drops = Path()
                for (i, x) in [10.0, 18.0, 26.0, 32.0].enumerated() {
                    let y = 21 + ((t * 14) + Double(i) * 4).truncatingRemainder(dividingBy: 11)
                    drops.move(to: CGPoint(x: x, y: y))
                    drops.addLine(to: CGPoint(x: x - 1, y: y + 3))
                }
                ctx.stroke(drops, with: .color(Theme.periwinkle), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
            .frame(width: size * 0.4, height: size * 0.34)
        }
    }
}

/// Little hearts drifting up.
private struct Hearts: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3) { i in
                    let progress = (t / 1.8 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Doodle(symbol: "heart", fill: Theme.pink, size: size * (0.09 + CGFloat(i) * 0.02))
                        .offset(x: CGFloat(i - 1) * size * 0.13 + sin(progress * .pi * 2) * 3, y: -progress * size * 0.36)
                        .opacity(1 - progress)
                }
            }
        }
    }
}

// MARK: - Speech bubble

/// Dialogue bubble: ink outline, a tail pointing at Pochi, a handwritten name tag,
/// and a line typed out with a cursor. The bubble hugs its text, but the space it sits in
/// is always 3 lines high so the screen below never moves.
struct SpeechBubble: View {
    let text: String
    @State private var shown = 0

    private static let font = Font.system(size: 15, weight: .medium)

    var body: some View {
        ZStack(alignment: .leading) {
            // Reserves the height of a full 3-line bubble.
            bubble { Text(" ").lineLimit(3, reservesSpace: true) }
                .hidden()

            bubble {
                ZStack(alignment: .topLeading) {
                    Text(text).hidden()
                    Text(text.prefix(shown)) + Text(shown < text.count ? "▌" : "").foregroundColor(Theme.accent)
                }
                .lineLimit(3)
            }
            .id(text)
            .transition(.scale(scale: 0.92, anchor: .leading).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: text)
        .task(id: text) {
            shown = 0
            for i in 1...max(text.count, 1) {
                try? await Task.sleep(for: .milliseconds(25))
                shown = i
            }
        }
    }

    private func bubble(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pochi")
                .font(Theme.hand(15))
                .foregroundStyle(Theme.accent)
            content()
                .font(Self.font)
                .foregroundStyle(Theme.ink)
        }
        .padding(.leading, BubbleShape.tail + 14)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background {
            ZStack {
                BubbleShape().fill(Theme.line).offset(Theme.lift)
                BubbleShape().fill(Theme.card)
                BubbleShape().stroke(Theme.line, lineWidth: Theme.outline)
            }
        }
        .padding(.trailing, Theme.lift.width)
    }
}

/// Rounded bubble with a small tail on the left edge.
struct BubbleShape: Shape {
    static let tail: CGFloat = 10
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        let l = rect.minX + Self.tail, r = rect.maxX, t = rect.minY, b = rect.maxY, cy = rect.midY
        let rad = min(radius, (b - t) / 2)
        var path = Path()
        path.move(to: CGPoint(x: l + rad, y: t))
        path.addArc(tangent1End: CGPoint(x: r, y: t), tangent2End: CGPoint(x: r, y: b), radius: rad)
        path.addArc(tangent1End: CGPoint(x: r, y: b), tangent2End: CGPoint(x: l, y: b), radius: rad)
        path.addArc(tangent1End: CGPoint(x: l, y: b), tangent2End: CGPoint(x: l, y: t), radius: rad)
        path.addLine(to: CGPoint(x: l, y: cy + 7))
        path.addLine(to: CGPoint(x: rect.minX, y: cy))
        path.addLine(to: CGPoint(x: l, y: cy - 7))
        path.addArc(tangent1End: CGPoint(x: l, y: t), tangent2End: CGPoint(x: r, y: t), radius: rad)
        path.closeSubpath()
        return path
    }
}

// MARK: - Mood

enum CorgiMood {
    case empty, nothing, started, halfway, perfect
    /// Neglected for days: the gauges are low.
    case sulking

    init(stats: GameStats, care: PochiCare) {
        if stats.habitCount == 0 { self = .empty; return }
        // Low gauges and nothing done yet today: it sulks. One check-in is enough to cheer it up;
        // the gauges themselves take a few good days to fill back up.
        if care.health < PochiCare.sulkThreshold && stats.todayDone == 0 { self = .sulking; return }
        let ratio = Double(stats.todayDone) / Double(stats.habitCount)
        switch ratio {
        case 0: self = .nothing
        case ..<0.5: self = .started
        case ..<1: self = .halfway
        default: self = .perfect
        }
    }

    var lines: [String] {
        switch self {
        case .empty: [
            "Aucune habitude. Audacieux. Paresseux, mais audacieux.",
            "Une app d'habitudes sans habitudes. Très conceptuel.",
            "Je t'attends. Couché. Comme d'habitude.",
        ]
        case .nothing: [
            "Rien coché. Je fais la sieste en solidarité.",
            "Zéro. Même moi j'ai fait plus, et je dors.",
            "Félicitations pour être en vie. C'est déjà ça.",
            "Le canapé t'envoie ses remerciements.",
            "Impressionnant. Une journée entière à ne rien faire.",
            "Je scrolle. Toi aussi, visiblement.",
            "Encore une vidéo et je m'y mets. Comme toi, quoi.",
        ]
        case .started: [
            "Progrès. Si on plisse très fort les yeux.",
            "Une case cochée. Tu veux une médaille ? Moi non plus.",
            "Quelle fusée. Lente, molle, et presque sans carburant.",
            "C'est un début. Un tout petit, minuscule début.",
        ]
        case .halfway: [
            "Plus de la moitié. Je suis presque impressionné. Presque.",
            "Pas mal. Pour quelqu'un comme toi, je veux dire.",
            "Tu y es presque. Ne gâche pas tout, pour une fois.",
            "J'en déduis une chose : tu as une volonté. Possiblement.",
        ]
        case .sulking: [
            "Je mange plus. Je regarde le mur. Merci.",
            "Ma gamelle est vide. Comme mes espoirs.",
            "Ça fait des jours. Je commence à oublier ta tête.",
            "Je boude. Coche un truc et j'y réfléchirai.",
            "Il pleut. Juste au-dessus de moi. Évidemment.",
        ]
        case .perfect: [
            "Tout coché. Je suppose que je dois applaudir. Sans mains.",
            "Journée parfaite. Profites-en, ça n'arrivera plus.",
            "Bravo. Je préviens les médias. Ah non, personne s'en fiche.",
            "Parfait. Qui es-tu et qu'as-tu fait de mon humain ?",
        ]
        }
    }

    var pose: CorgiPose {
        switch self {
        case .empty: return .box
        case .nothing:
            // Asleep at night; by day, doomscrolling or rolled up in a plaid. Which one changes every day.
            let hour = Day.calendar.component(.hour, from: .now)
            if hour >= 22 || hour < 7 { return Self.dayIndex % 2 == 0 ? .sleeping : .basket }
            return Self.dayIndex % 2 == 0 ? .phone : .blanket
        case .started:
            // Bundled up in winter; otherwise sitting or snacking, one day out of two.
            let month = Day.calendar.component(.month, from: .now)
            if [12, 1, 2].contains(month) { return .scarf }
            return Self.dayIndex % 2 == 0 ? .sitting : .bowl
        case .halfway: return .ball
        case .perfect: return .happy
        case .sulking: return .sulking
        }
    }

    func line(nudge: Int) -> String {
        lines[(Self.dayIndex + nudge) % lines.count]
    }

    private static var dayIndex: Int {
        Day.calendar.ordinality(of: .day, in: .year, for: .now) ?? 0
    }
}

#if DEBUG
/// Every pose side by side. Launch with `-corgiGallery` to see it.
struct CorgiGallery: View {
    private let poses: [(CorgiPose, String)] = [
        (.box, "BOX"), (.sleeping, "SLEEPING"), (.basket, "BASKET"), (.phone, "PHONE"), (.blanket, "BLANKET"),
        (.sitting, "SITTING"), (.bowl, "BOWL"), (.scarf, "SCARF"), (.sulking, "SULKING"), (.ball, "BALL"), (.happy, "HAPPY"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                ForEach(poses, id: \.1) { pose, name in
                    HStack(spacing: 20) {
                        PochiView(pose: pose)
                        Text(name).font(Theme.mono(16)).tracking(2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(30)
            .padding(.top, 40)
        }
        .background(DottedPaper())
    }
}
#endif
