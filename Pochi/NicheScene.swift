import SwiftUI

/// Time of day for the niche scene.
enum TimeOfDay: CaseIterable {
    case dawn, day, dusk, night

    static var current: TimeOfDay {
        var hour = Day.calendar.component(.hour, from: .now)
        #if DEBUG
        // Launch with `-debugHour 21` to see another time of day.
        if let forced = UserDefaults.standard.string(forKey: "debugHour").flatMap(Int.init) { hour = forced }
        #endif
        switch hour {
        case 6..<8: return .dawn
        case 8..<18: return .day
        case 18..<21: return .dusk
        default: return .night
        }
    }

    /// Sky colours, top to bottom.
    var sky: [Color] {
        switch self {
        case .dawn: [Color(hex: 0xC9B8E8), Color(hex: 0xFBD9B8)]
        case .day: [Color(hex: 0x9FD3F2), Color(hex: 0xDDF1FA)]
        case .dusk: [Color(hex: 0xF0A07E), Color(hex: 0xF9D49C)]
        case .night: [Color(hex: 0x2E3566), Color(hex: 0x4D5394)]
        }
    }

    /// Back and front hill colours.
    var hills: (back: Color, front: Color) {
        self == .night ? (Color(hex: 0x4F8A73), Color(hex: 0x66A386)) : (Color(hex: 0x7FCB9A), Theme.mint)
    }
}

/// Pochi's patch of land as a flat sketchbook illustration on a 300 × 240 canvas.
/// Each level adds a piece of the doghouse and its yard, each perfect day a tree.
struct NicheScene {
    let level: Int
    let trees: Int
    let fed: Bool
    let time: TimeOfDay
    let t: Double

    static let size = CGSize(width: 300, height: 240)
    /// Where Pochi stands, in canvas coordinates (the bottom of the drawing).
    static let pochiSpot = CGPoint(x: 242, y: 218)

    private static let wood = Color(hex: 0xE7B377)
    private static let stone = Color(hex: 0xD8D0C2)
    private static let trunk = Color(hex: 0xB07A4F)
    private static let leaves = Color(hex: 0x5DBB7E)

    /// Spots for trees on the back hill, filled in order; later trees go in front.
    private static let treeSlots: [CGPoint] = [
        CGPoint(x: 40, y: 150), CGPoint(x: 262, y: 146), CGPoint(x: 86, y: 140), CGPoint(x: 236, y: 152),
        CGPoint(x: 18, y: 160), CGPoint(x: 284, y: 160), CGPoint(x: 64, y: 156), CGPoint(x: 112, y: 146),
        CGPoint(x: 24, y: 214), CGPoint(x: 112, y: 232), CGPoint(x: 60, y: 236), CGPoint(x: 290, y: 238),
    ]

    func draw(in ctx: GraphicsContext) {
        sky(ctx)
        hills(ctx)
        for slot in Self.treeSlots.prefix(min(trees, 8)) { tree(ctx, at: slot, scale: 0.8) }
        if level >= 6 { fence(ctx) }
        if level >= 1 { outlined(ctx, oval(170, 190, 62, 10), Color(hex: 0xD9B48A)) }
        if level >= 2 { outlined(ctx, Path(roundedRect: CGRect(x: 128, y: 178, width: 84, height: 12), cornerRadius: 3), Self.stone) }
        if level >= 3 { house(ctx) }
        if level >= 7 { path(ctx) }
        if level >= 5 { bowl(ctx) }
        if level >= 8 { lamp(ctx) }
        if level >= 9 { mailbox(ctx) }
        for slot in Self.treeSlots.dropFirst(8).prefix(max(trees - 8, 0)) { tree(ctx, at: slot, scale: 1) }
    }

    // MARK: Backdrop

    private func sky(_ ctx: GraphicsContext) {
        let rect = CGRect(origin: .zero, size: Self.size)
        ctx.fill(Path(rect), with: .linearGradient(Gradient(colors: time.sky), startPoint: .zero,
                                                    endPoint: CGPoint(x: 0, y: 170)))
        switch time {
        case .day:
            sun(ctx, at: CGPoint(x: 246, y: 48), radius: 20)
        case .dawn, .dusk:
            sun(ctx, at: CGPoint(x: time == .dawn ? 60 : 110, y: 130), radius: 24)
        case .night:
            var moon = oval(240, 50, 18, 18)
            moon = moon.subtracting(oval(250, 42, 15, 15))
            outlined(ctx, moon, Theme.yellow)
            for (i, star) in [CGPoint(x: 40, y: 34), CGPoint(x: 120, y: 22), CGPoint(x: 176, y: 60), CGPoint(x: 80, y: 80), CGPoint(x: 200, y: 26)].enumerated() {
                let twinkle = 0.6 + 0.4 * sin(t * 2 + Double(i))
                sparkle(ctx, at: star, radius: 4 * twinkle)
            }
        }
        if time != .night {
            let drift = (t * 4).truncatingRemainder(dividingBy: 360)
            cloud(ctx, at: CGPoint(x: (40 + drift).truncatingRemainder(dividingBy: 360) - 30, y: 40), scale: 1)
            cloud(ctx, at: CGPoint(x: (190 + drift * 0.7).truncatingRemainder(dividingBy: 360) - 30, y: 76), scale: 0.75)
        }
    }

    private func hills(_ ctx: GraphicsContext) {
        outlined(ctx, oval(70, 200, 150, 60), time.hills.back)
        outlined(ctx, oval(250, 206, 130, 56), time.hills.back)
        var front = Path()
        front.move(to: CGPoint(x: -4, y: 182))
        front.addQuadCurve(to: CGPoint(x: 304, y: 176), control: CGPoint(x: 150, y: 160))
        front.addLine(to: CGPoint(x: 304, y: 244))
        front.addLine(to: CGPoint(x: -4, y: 244))
        front.closeSubpath()
        outlined(ctx, front, time.hills.front)
        // A few grass tufts.
        var tufts = Path()
        for x in [30.0, 98, 250, 286] {
            let y = 204.0 + (x.truncatingRemainder(dividingBy: 3)) * 6
            tufts.move(to: CGPoint(x: x - 4, y: y))
            tufts.addLine(to: CGPoint(x: x - 2, y: y - 6))
            tufts.move(to: CGPoint(x: x, y: y))
            tufts.addLine(to: CGPoint(x: x + 2, y: y - 7))
        }
        ctx.stroke(tufts, with: .color(Theme.darkInk.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    // MARK: Doghouse and yard

    private func house(_ ctx: GraphicsContext) {
        let roofed = level >= 4
        if level >= 10 { flag(ctx) }
        outlined(ctx, Path(CGRect(x: 138, y: 126, width: 64, height: 54)), Self.wood)
        // Planks.
        var planks = Path()
        for y in stride(from: 138.0, to: 178, by: 11) {
            planks.move(to: CGPoint(x: 140, y: y))
            planks.addLine(to: CGPoint(x: 200, y: y))
        }
        ctx.stroke(planks, with: .color(Theme.darkInk.opacity(0.18)), lineWidth: 1.5)
        // Door: an arch.
        var door = Path()
        door.move(to: CGPoint(x: 156, y: 180))
        door.addLine(to: CGPoint(x: 156, y: 160))
        door.addArc(center: CGPoint(x: 170, y: 160), radius: 14, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
        door.addLine(to: CGPoint(x: 184, y: 180))
        outlined(ctx, door, Theme.darkInk.opacity(0.85))
        if roofed {
            var roof = Path()
            roof.addLines([CGPoint(x: 128, y: 132), CGPoint(x: 170, y: 96), CGPoint(x: 212, y: 132)])
            roof.closeSubpath()
            outlined(ctx, roof, Theme.coral)
            ctx.draw(Text("POCHI").font(.system(size: 8, weight: .heavy)).foregroundStyle(Theme.darkInk),
                     at: CGPoint(x: 170, y: 121))
        }
    }

    private func bowl(_ ctx: GraphicsContext) {
        if fed {
            for (x, y) in [(206.0, 202.0), (212.0, 200.0), (218.0, 202.0), (212.0, 204.0)] {
                outlined(ctx, oval(x, y, 3.2, 2.6), Color(hex: 0xA8683F), width: 1.4)
            }
        }
        var dish = Path()
        dish.move(to: CGPoint(x: 198, y: 204))
        dish.addLine(to: CGPoint(x: 226, y: 204))
        dish.addLine(to: CGPoint(x: 222, y: 214))
        dish.addLine(to: CGPoint(x: 202, y: 214))
        dish.closeSubpath()
        outlined(ctx, dish, Theme.periwinkle)
    }

    private func fence(_ ctx: GraphicsContext) {
        let rail = Color(hex: 0xFFF6E6)
        outlined(ctx, Path(CGRect(x: 8, y: 166, width: 100, height: 5)), rail, width: 2)
        outlined(ctx, Path(CGRect(x: 8, y: 178, width: 100, height: 5)), rail, width: 2)
        for x in stride(from: 12.0, through: 100, by: 16) {
            var post = Path()
            post.addLines([CGPoint(x: x, y: 190), CGPoint(x: x, y: 162), CGPoint(x: x + 4, y: 157),
                           CGPoint(x: x + 8, y: 162), CGPoint(x: x + 8, y: 190)])
            post.closeSubpath()
            outlined(ctx, post, rail, width: 2)
        }
    }

    private func path(_ ctx: GraphicsContext) {
        for (i, (x, y)) in [(166.0, 200.0), (156.0, 214.0), (146.0, 229.0)].enumerated() {
            outlined(ctx, oval(x, y, 13 + Double(i) * 2, 5 + Double(i)), Self.stone, width: 2)
        }
    }

    private func lamp(_ ctx: GraphicsContext) {
        if time == .night || time == .dusk {
            let center = CGPoint(x: 262, y: 128)
            ctx.fill(oval(center.x, center.y, 40, 40),
                     with: .radialGradient(Gradient(colors: [Theme.yellow.opacity(0.55), .clear]),
                                           center: center, startRadius: 0, endRadius: 40))
        }
        outlined(ctx, Path(roundedRect: CGRect(x: 259, y: 132, width: 6, height: 70), cornerRadius: 2), Theme.darkInk)
        outlined(ctx, Path(roundedRect: CGRect(x: 252, y: 118, width: 20, height: 16), cornerRadius: 4),
                 time == .day ? Theme.card : Theme.yellow)
    }

    private func mailbox(_ ctx: GraphicsContext) {
        outlined(ctx, Path(CGRect(x: 117, y: 176, width: 5, height: 22)), Self.wood, width: 2)
        outlined(ctx, Path(roundedRect: CGRect(x: 106, y: 162, width: 26, height: 16), cornerRadius: 7), Theme.periwinkle)
        var raised = Path()
        raised.addLines([CGPoint(x: 130, y: 166), CGPoint(x: 130, y: 152), CGPoint(x: 138, y: 155), CGPoint(x: 130, y: 158)])
        ctx.stroke(raised, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        ctx.fill(Path(CGRect(x: 130, y: 152, width: 7, height: 6)), with: .color(Theme.coral))
    }

    private func flag(_ ctx: GraphicsContext) {
        var pole = Path()
        pole.move(to: CGPoint(x: 170, y: 98))
        pole.addLine(to: CGPoint(x: 170, y: 64))
        ctx.stroke(pole, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        let wave = sin(t * 4) * 3
        var cloth = Path()
        cloth.move(to: CGPoint(x: 171, y: 65))
        cloth.addQuadCurve(to: CGPoint(x: 194, y: 72 + wave), control: CGPoint(x: 182, y: 62 - wave))
        cloth.addQuadCurve(to: CGPoint(x: 171, y: 80), control: CGPoint(x: 182, y: 82 + wave))
        cloth.closeSubpath()
        outlined(ctx, cloth, Theme.yellow, width: 2)
    }

    // MARK: Little things

    private func tree(_ ctx: GraphicsContext, at base: CGPoint, scale s: Double) {
        let sway = sin(t * 1.5 + base.x) * 1.2
        outlined(ctx, Path(roundedRect: CGRect(x: base.x - 3 * s, y: base.y - 18 * s, width: 6 * s, height: 20 * s),
                           cornerRadius: 2), Self.trunk, width: 2)
        var crown = oval(base.x + sway, base.y - 30 * s, 15 * s, 16 * s)
        crown = crown.union(oval(base.x - 8 * s + sway, base.y - 22 * s, 10 * s, 9 * s))
        crown = crown.union(oval(base.x + 8 * s + sway, base.y - 22 * s, 10 * s, 9 * s))
        outlined(ctx, crown, time == .night ? Color(hex: 0x3F8A62) : Self.leaves, width: 2.2)
    }

    private func sun(_ ctx: GraphicsContext, at c: CGPoint, radius r: Double) {
        var rays = Path()
        for i in 0..<8 {
            let a = Double(i) / 8 * .pi * 2 + t * 0.3
            rays.move(to: CGPoint(x: c.x + cos(a) * (r + 5), y: c.y + sin(a) * (r + 5)))
            rays.addLine(to: CGPoint(x: c.x + cos(a) * (r + 11), y: c.y + sin(a) * (r + 11)))
        }
        ctx.stroke(rays, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        outlined(ctx, oval(c.x, c.y, r, r), Theme.yellow)
    }

    private func cloud(_ ctx: GraphicsContext, at c: CGPoint, scale s: Double) {
        var cloud = Path(roundedRect: CGRect(x: c.x - 26 * s, y: c.y, width: 52 * s, height: 13 * s), cornerRadius: 6.5 * s)
        cloud = cloud.union(oval(c.x - 8 * s, c.y + 1 * s, 11 * s, 11 * s))
        cloud = cloud.union(oval(c.x + 8 * s, c.y - 1 * s, 13 * s, 13 * s))
        outlined(ctx, cloud, .white, width: 2.2)
    }

    private func sparkle(_ ctx: GraphicsContext, at c: CGPoint, radius r: Double) {
        var star = Path()
        star.move(to: CGPoint(x: c.x, y: c.y - r * 2))
        star.addQuadCurve(to: CGPoint(x: c.x + r * 2, y: c.y), control: c)
        star.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r * 2), control: c)
        star.addQuadCurve(to: CGPoint(x: c.x - r * 2, y: c.y), control: c)
        star.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r * 2), control: c)
        ctx.fill(star, with: .color(Theme.yellow))
    }

    private func oval(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    private func outlined(_ ctx: GraphicsContext, _ path: Path, _ fill: Color, width: Double = 2.6) {
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(Theme.darkInk), style: StrokeStyle(lineWidth: width, lineJoin: .round))
    }
}
