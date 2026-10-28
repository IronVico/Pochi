import CoreGraphics
import Foundation

/// A tiny software renderer for Pochi's isometric pixel-art world. The scene is drawn
/// at low resolution (one array entry per pixel) and shown scaled up without smoothing.
/// `frame` advances ~7 times a second and drives the little animations.
enum IsoWorld {
    static let width = 104
    static let height = 88

    /// Mini Pochi's state in the world.
    enum Pochi {
        case standing, sitting, sleeping, phone, happy
        /// Neglected: curled up on the doormat under a rain cloud.
        case sulking
    }

    private static let iso = Iso(originX: 52, originY: 24, unit: 8)

    private static let treeSlots: [(x: Double, y: Double)] = [
        (0.6, 0.6), (5.3, 0.7), (0.5, 2.4), (5.5, 1.8), (0.6, 5.3), (5.4, 5.3),
        (1.6, 0.5), (4.4, 0.5), (0.4, 3.6), (4.3, 5.6), (1.5, 5.6), (5.6, 4.6),
    ]
    static var maxTrees: Int { treeSlots.count }

    private static let grass: UInt32 = 0x5BB85A
    private static let dirt: UInt32 = 0x8C5C30
    private static let wood: UInt32 = 0xE3A867

    /// The time of day the island is shown at, from the real clock.
    enum Phase: CaseIterable {
        case dawn, day, dusk, night

        static var current: Phase {
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
        fileprivate var sky: (top: UInt32, bottom: UInt32) {
            switch self {
            case .dawn: (0x5B5F9E, 0xF4B48C)
            case .day: (0x4A9BE0, 0xA9DAF2)
            case .dusk: (0x352A55, 0xE07A5A)
            case .night: (0x0B0F1E, 0x1C2342)
            }
        }

        /// Light on the island, as an RGB multiplier.
        fileprivate var light: (r: Double, g: Double, b: Double) {
            switch self {
            case .dawn: (1, 0.9, 0.88)
            case .day: (1, 1, 1)
            case .dusk: (1, 0.8, 0.72)
            case .night: (0.5, 0.56, 0.82)
            }
        }

        /// Window and lamp switched on.
        fileprivate var lightsOn: Bool { self != .day }
    }

    /// `wander`: Pochi walks around the island (when awake); false keeps it still, e.g. while petted.
    /// `fed`: kibble in the bowl, or an empty bowl when Pochi is hungry.
    static func render(level: Int, trees: Int, pochi: Pochi, wander: Bool = true, fed: Bool = true,
                       phase: Phase = .current, frame: Int) -> CGImage? {
        var b = PixelBuffer(width: width, height: height, fill: phase.sky.top)

        // The sky glows on its own: the island's light doesn't apply to it.
        b.glowing = true
        sky(&b, phase, frame: frame)
        b.glowing = false

        island(&b)

        // Flat things on the ground: shadows, then the path.
        if level >= 2 { b.fill(footprint(1.9, 1.5, 2.6, 2.6), PixelBuffer.shade(grass, 0.8)) }
        for slot in treeSlots.prefix(trees) {
            b.fill(footprint(slot.x - 0.45, slot.y - 0.45, 1, 1), PixelBuffer.shade(grass, 0.8))
        }
        if level >= 7 {
            for (x, y) in [(2.75, 3.9), (3.05, 4.6), (2.8, 5.3)] {
                b.box(iso, x, y, 0, 0.55, 0.45, 0.06, color: 0xB4B4B4)
            }
        }

        // Everything else, back to front.
        var items: [(depth: Double, draw: (inout PixelBuffer) -> Void)] = []

        if level >= 6 {
            for i in 0..<6 {
                let x = 0.4 + Double(i)
                items.append((x, { $0.box(iso, x, 0.05, 0, 0.25, 0.25, 0.6, color: 0xEAD7B5) }))
                if i > 0 {
                    let y = 0.4 + Double(i)
                    items.append((y, { $0.box(iso, 0.05, y, 0, 0.25, 0.25, 0.6, color: 0xEAD7B5) }))
                }
            }
            items.append((0.1, {
                $0.box(iso, 0.3, 0.12, 0.35, 5.4, 0.12, 0.12, color: 0xD9C29A, outline: false)
                $0.box(iso, 0.12, 0.3, 0.35, 0.12, 5.4, 0.12, color: 0xD9C29A, outline: false)
            }))
        }
        if level >= 2 {
            items.append((5.6, { house(&$0, level: level, lit: phase.lightsOn, frame: frame) }))
        }
        if level >= 5 {
            items.append((8.4, {
                $0.box(iso, 4.3, 3.8, 0, 0.5, 0.5, 0.18, color: 0x4FA3FF, top: fed ? 0xC8925A : 0x1E3F6B)
                if fed {
                    // A few darker kibbles on top.
                    for (x, y) in [(4.45, 3.95), (4.6, 4.1), (4.5, 4.15)] {
                        let p = iso.point(x, y, 0.18)
                        $0.set(Int(p.x), Int(p.y), 0x8C5C30)
                    }
                }
            }))
        }
        if level >= 8 {
            items.append((5.9, {
                $0.verticalLine(iso, 1.47, 4.57, from: 0, to: 1.4, color: 0x3A3A3A)
                $0.glowing = phase.lightsOn
                $0.box(iso, 1.32, 4.42, 1.4, 0.3, 0.3, 0.3,
                       color: !phase.lightsOn ? 0xC8C8C8 : frame % 6 < 5 ? 0xFFD15C : 0xFFE9A0)
                $0.glowing = false
            }))
        }
        if level >= 9 {
            items.append((2.6, {
                $0.verticalLine(iso, 1.26, 1.46, from: 0, to: 0.6, color: 0x8C5C30)
                $0.box(iso, 1.05, 1.25, 0.6, 0.45, 0.3, 0.3, color: 0xE5484D)
            }))
        }
        for (i, slot) in treeSlots.prefix(trees).enumerated() {
            items.append((slot.x + slot.y, { tree(&$0, kind: i % 3, x: slot.x, y: slot.y) }))
        }
        let walker = pochiPosition(pochi, wander: wander, frame: frame)
        items.append((walker.x + walker.y + 0.3, { drawPochi(&$0, pochi, at: walker, frame: frame) }))

        for item in items.sorted(by: { $0.depth < $1.depth }) {
            item.draw(&b)
        }
        b.applyLight(phase.light)
        return b.cgImage()
    }

    // MARK: - Sky

    private static func sky(_ b: inout PixelBuffer, _ phase: Phase, frame: Int) {
        // Gradient in a few flat bands, like old games.
        let bands = 6
        for y in 0..<height {
            let band = min(y * bands / (height * 3 / 4), bands - 1)
            let color = PixelBuffer.mix(phase.sky.top, phase.sky.bottom, Double(band) / Double(bands - 1))
            for x in 0..<width { b.set(x, y, color) }
        }

        switch phase {
        case .night:
            let stars = [(6, 5), (18, 12), (34, 3), (84, 22), (97, 17), (72, 2), (9, 26), (99, 33), (4, 44), (49, 7), (62, 14), (28, 20)]
            for (i, star) in stars.enumerated() {
                let bright = (frame / 3 + i * 7) % 11 == 0
                b.set(star.0, star.1, bright ? 0xE6EAFF : 0x5A6288)
            }
            // Crescent moon: a disc with a sky-coloured disc bitten out of it.
            disc(&b, cx: 86, cy: 10, r: 5, color: 0xEEF0F8)
            disc(&b, cx: 89, cy: 8, r: 5, color: phase.sky.top)
        case .day:
            disc(&b, cx: 86, cy: 11, r: 6, color: 0xFFD96A)
            disc(&b, cx: 86, cy: 11, r: 4, color: 0xFFEFA8)
            clouds(&b, frame: frame, color: 0xF4FAFF, shadow: 0xD3E6F5)
        case .dawn, .dusk:
            let x = phase == .dawn ? 14 : 90
            disc(&b, cx: x, cy: 21, r: 7, color: 0xFFA25C)
            disc(&b, cx: x, cy: 21, r: 5, color: 0xFFC98A)
            clouds(&b, frame: frame, color: 0xF6C1B0, shadow: 0xD99A94)
        }
    }

    private static func disc(_ b: inout PixelBuffer, cx: Int, cy: Int, r: Int, color: UInt32) {
        for y in -r...r {
            for x in -r...r where x * x + y * y <= r * r + r / 2 { b.set(cx + x, cy + y, color) }
        }
    }

    /// Blocky clouds drifting slowly to the right, wrapping around.
    private static func clouds(_ b: inout PixelBuffer, frame: Int, color: UInt32, shadow: UInt32) {
        let shapes: [(x: Int, y: Int, w: Int)] = [(10, 9, 16), (60, 4, 12), (34, 18, 10)]
        for (i, cloud) in shapes.enumerated() {
            let span = width + 30
            let x = (cloud.x + frame / (5 + i * 2)) % span - 15
            // Each row narrower than the one below; `stride` stays empty if a row has no width left.
            for dx in stride(from: 0, to: cloud.w, by: 1) { b.set(x + dx, cloud.y + 2, shadow) }
            for dx in stride(from: 1, to: cloud.w - 1, by: 1) { b.set(x + dx, cloud.y + 1, color) }
            for dx in stride(from: 3, to: cloud.w - 3, by: 1) { b.set(x + dx, cloud.y, color) }
            for dx in stride(from: 5, to: cloud.w - 5, by: 1) { b.set(x + dx, cloud.y - 1, color) }
        }
    }

    // MARK: - Pieces

    private static func island(_ b: inout PixelBuffer) {
        b.box(iso, 0, 0, -1.5, 6, 6, 1.2, color: dirt)
        // Thicken the bottom edges so the stepped outline doesn't look dotted against a light sky.
        let edge = PixelBuffer.shade(dirt, 0.4)
        for dy in [-1.0, -2.0] {
            let shift = { (p: CGPoint) in CGPoint(x: p.x, y: p.y + dy) }
            b.line(shift(iso.point(0, 6, -1.5)), shift(iso.point(6, 6, -1.5)), PixelBuffer.shade(dirt, 0.78))
            b.line(shift(iso.point(6, 0, -1.5)), shift(iso.point(6, 6, -1.5)), PixelBuffer.shade(dirt, 0.6))
        }
        b.line(iso.point(0, 6, -1.5), iso.point(6, 6, -1.5), edge)
        b.line(iso.point(6, 0, -1.5), iso.point(6, 6, -1.5), edge)
        // Earth strata and pebbles on both sides.
        for z in [-0.75, -1.15] {
            b.line(iso.point(0, 6, z), iso.point(6, 6, z), PixelBuffer.shade(dirt, 0.62))
            b.line(iso.point(6, 0, z), iso.point(6, 6, z), PixelBuffer.shade(dirt, 0.48))
        }
        var random = SeededRandom(seed: 7)
        for _ in 0..<14 {
            let along = random.next() * 6, z = -0.5 - random.next() * 0.9
            let left = random.next() < 0.5
            let p = left ? iso.point(along, 6, z) : iso.point(6, along, z)
            b.set(Int(p.x), Int(p.y), left ? 0xA87A4A : 0x7A5028)
        }

        b.box(iso, 0, 0, -0.3, 6, 6, 0.3, color: grass)
        // Grass tufts, darker and lighter.
        var tufts = SeededRandom(seed: 3)
        for _ in 0..<70 {
            let p = iso.point(tufts.next() * 5.8 + 0.1, tufts.next() * 5.8 + 0.1, 0)
            let light = tufts.next() < 0.4
            b.set(Int(p.x), Int(p.y), light ? 0x7DD47A : 0x449A45)
            if !light { b.set(Int(p.x), Int(p.y) - 1, 0x449A45) }
        }
    }

    private static func house(_ b: inout PixelBuffer, level: Int, lit: Bool, frame: Int) {
        b.box(iso, 1.9, 1.5, 0, 2.2, 2.2, 0.25, color: 0xB8B8B8)
        guard level >= 3 else { return }

        b.box(iso, 2, 1.6, 0.25, 2, 2, 1.5, color: wood)
        // Planks.
        for z in [0.65, 1.05, 1.45] {
            b.line(iso.point(2, 3.6, z), iso.point(4, 3.6, z), PixelBuffer.shade(wood, 0.62))
            b.line(iso.point(4, 1.6, z), iso.point(4, 3.6, z), PixelBuffer.shade(wood, 0.48))
        }
        // Door with its frame, and a doormat; window on the right, lit at night.
        b.fill([iso.point(2.6, 3.6, 0.25), iso.point(3.4, 3.6, 0.25),
                iso.point(3.4, 3.6, 1.35), iso.point(2.6, 3.6, 1.35)], PixelBuffer.shade(wood, 0.45))
        b.fill([iso.point(2.7, 3.6, 0.25), iso.point(3.3, 3.6, 0.25),
                iso.point(3.3, 3.6, 1.25), iso.point(2.7, 3.6, 1.25)], 0x2A180C)
        b.fill([iso.point(2.65, 3.7, 0.01), iso.point(3.35, 3.7, 0.01),
                iso.point(3.35, 4.1, 0.01), iso.point(2.65, 4.1, 0.01)], 0xC0453F)
        b.fill([iso.point(4, 2.25, 0.8), iso.point(4, 2.95, 0.8),
                iso.point(4, 2.95, 1.4), iso.point(4, 2.25, 1.4)], PixelBuffer.shade(wood, 0.4))
        b.glowing = lit
        b.fill([iso.point(4, 2.35, 0.88), iso.point(4, 2.85, 0.88),
                iso.point(4, 2.85, 1.32), iso.point(4, 2.35, 1.32)], lit ? 0xFFD15C : 0x9FC8E8)
        b.glowing = false
        guard level >= 4 else { return }

        // Back slope, gable wall, front slope with rows of tiles.
        b.fill([iso.point(1.8, 1.4, 1.75), iso.point(4, 1.4, 1.75),
                iso.point(4, 2.6, 2.75), iso.point(1.8, 2.6, 2.75)], 0xB23E38)
        b.fill([iso.point(4, 1.6, 1.75), iso.point(4, 3.6, 1.75), iso.point(4, 2.6, 2.75)], PixelBuffer.shade(wood, 0.6))
        b.line(iso.point(4, 1.6, 1.75), iso.point(4, 2.6, 2.75), 0x7A2420)
        let front = [iso.point(1.8, 3.8, 1.75), iso.point(4, 3.8, 1.75), iso.point(4, 2.6, 2.75), iso.point(1.8, 2.6, 2.75)]
        b.fill(front, 0xD9534C)
        for t in [0.33, 0.66] {
            let y = 3.8 - 1.2 * t, z = 1.75 + t
            b.line(iso.point(1.8, y, z), iso.point(4, y, z), 0xB23E38)
        }
        b.outline(front, 0x7A2420)
        guard level >= 10 else { return }

        b.verticalLine(iso, 2.1, 2.6, from: 2.75, to: 4.1, color: 0xF0F0F0)
        let wave = frame % 4 < 2 ? 0.0 : 0.1
        b.fill([iso.point(2.15, 2.6, 4.1), iso.point(2.9, 2.6, 3.95 - wave),
                iso.point(2.9, 2.6, 3.55 - wave), iso.point(2.15, 2.6, 3.7)], 0xFFD15C)
    }

    /// 0 = round tree, 1 = pine, 2 = flower bush.
    private static func tree(_ b: inout PixelBuffer, kind: Int, x: Double, y: Double) {
        switch kind {
        case 0:
            b.box(iso, x - 0.1, y - 0.1, 0, 0.2, 0.2, 0.5, color: 0x8C5C30)
            b.box(iso, x - 0.4, y - 0.4, 0.5, 0.8, 0.8, 0.8, color: 0x4CAF50, top: 0x6CCB6A)
        case 1:
            b.box(iso, x - 0.1, y - 0.1, 0, 0.2, 0.2, 0.3, color: 0x8C5C30)
            b.box(iso, x - 0.45, y - 0.45, 0.3, 0.9, 0.9, 0.4, color: 0x2E8B57)
            b.box(iso, x - 0.32, y - 0.32, 0.7, 0.64, 0.64, 0.4, color: 0x2E8B57)
            b.box(iso, x - 0.18, y - 0.18, 1.1, 0.36, 0.36, 0.4, color: 0x2E8B57)
        default:
            b.box(iso, x - 0.25, y - 0.25, 0, 0.5, 0.5, 0.3, color: 0x4CAF50)
            let top = iso.point(x, y, 0.3)
            b.set(Int(top.x), Int(top.y), 0xF4A3A3)
            b.set(Int(top.x) - 2, Int(top.y) + 1, 0xFFD15C)
            b.set(Int(top.x) + 2, Int(top.y) + 1, 0xF4A3A3)
        }
    }

    // MARK: - Mini Pochi

    private static let pochiPalette: [Character: UInt32] = [
        "K": 0x2B1D16, "O": 0xE8913A, "D": 0xC46F2A, "W": 0xFFF6EA,
        "P": 0xF4A3A3, "N": 0x120C09, "E": 0x120C09,
        "L": 0xBFE3FF, "M": 0x5B8FCB,
    ]

    // 13 × 9, three-quarters to the left like the big Pochi.
    private static let pochiStanding = [
        ".K...K.......",
        "KPK.KPK......",
        "KOOOOOKKKKK..",
        "KOEOEOOOOOOK.",
        "KWWNWWOOOOOK.",
        ".KWWWWOOOODK.",
        "..KWWWWWWDK..",
        "..KWK...KWK..",
        "..KKK...KKK..",
    ]
    /// Sitting, rear down, front legs straight.
    private static let pochiSitting = [
        ".K...K.......",
        "KPK.KPK......",
        "KOOOOOKK.....",
        "KOEOEOOOK....",
        "KWWNWWOOOK...",
        ".KWWWWOOOOK..",
        "..KWWWOOODK..",
        "..KWKWWODDK..",
        "..KKKKKKKK...",
    ]
    /// Begging: up on its hind legs, front paws folded (like the portfolio's "beg").
    private static let pochiBeg = [
        ".K...K.......",
        "KPK.KPK......",
        "KOOOOOK......",
        "KOEOEOOK.....",
        "KWWNWWOK.....",
        ".KWWWWOK.....",
        "KWKWWWOOK....",
        "KKKWWWOOK....",
        "..KWWWODK....",
        "..KWKKWDK....",
        "..KK..KK.....",
    ]
    private static let pochiLying = [
        ".K...K.......",
        "KPK.KPK......",
        "KOOOOOKKKKK..",
        "KOEOEOOOOOOK.",
        "KWWNWWOOOOOK.",
        ".KWWWWOOOODK.",
        "..KKKKKKKKK..",
    ]

    /// Pochi's home spot: right of the doghouse, bowl in front of its nose.
    private static let pochiHome = (x: 5.2, y: 3.3)

    /// The walk around the front of the doghouse, there and back (so it never goes through it).
    private static let walkPath: [(x: Double, y: Double)] = [
        (5.2, 3.3), (4.9, 4.4), (3.6, 4.9), (2.0, 4.6), (1.2, 3.9),
        (2.0, 4.6), (3.6, 4.9), (4.9, 4.4),
    ]
    private static let walkSpeed = 0.11 // island units per frame
    /// Frames spent sniffing at each stop; longer at both ends of the walk.
    private static func pause(at index: Int) -> Int { index == 0 || index == 4 ? 30 : 8 }

    struct Walker {
        var x: Double
        var y: Double
        var moving = false
        /// Heading towards the right of the screen (the sprite is drawn mirrored).
        var facingRight = false
        /// Which stop of the walk it's pausing at, to vary what it does there.
        var stop = 0
    }

    private static func pochiPosition(_ pose: Pochi, wander: Bool, frame: Int) -> Walker {
        let home = Walker(x: pochiHome.x, y: pochiHome.y)
        guard pose != .sleeping, pose != .phone else { return home }
        if pose == .sulking { return Walker(x: 3.0, y: 4.25, facingRight: true) } // on the doormat
        // Not wandering (being petted): it stops right where it is.
        guard wander else {
            var here = pochiPosition(pose, wander: true, frame: frame)
            here.moving = false
            return here
        }

        // One full loop: walk each leg, pause at each stop.
        var legs: [(from: Int, frames: Int)] = []
        for i in walkPath.indices {
            let a = walkPath[i], b = walkPath[(i + 1) % walkPath.count]
            let length = hypot(b.x - a.x, b.y - a.y)
            legs.append((i, pause(at: i)))
            legs.append((i, -max(1, Int(length / walkSpeed)))) // negative = walking
        }
        let loop = legs.reduce(0) { $0 + abs($1.frames) }
        var t = frame % loop
        for leg in legs {
            let duration = abs(leg.frames)
            guard t >= duration else {
                let a = walkPath[leg.from], b = walkPath[(leg.from + 1) % walkPath.count]
                if leg.frames > 0 {
                    // Pausing: keep facing the way it came.
                    let previous = walkPath[(leg.from + walkPath.count - 1) % walkPath.count]
                    return Walker(x: a.x, y: a.y, facingRight: (a.x - a.y) > (previous.x - previous.y), stop: leg.from)
                }
                let progress = Double(t) / Double(duration)
                return Walker(x: a.x + (b.x - a.x) * progress, y: a.y + (b.y - a.y) * progress,
                              moving: true, facingRight: (b.x - b.y) > (a.x - a.y))
            }
            t -= duration
        }
        return home
    }

    private static func drawPochi(_ b: inout PixelBuffer, _ pose: Pochi, at walker: Walker, frame: Int) {
        let foot = iso.point(walker.x, walker.y, 0)

        // What it does: walks on all fours; at a stop, sits, sniffs around or begs depending on the day.
        enum Stance { case walk, stand, sit, beg, lie, phone }
        let stance: Stance
        if walker.moving {
            stance = .walk
        } else {
            switch pose {
            case .sleeping, .sulking: stance = .lie
            case .phone: stance = .phone
            case .happy: stance = .beg
            case .sitting: stance = .sit
            case .standing: stance = walker.stop % 2 == 0 ? .sit : .stand
            }
        }
        var grid: [[Character]] = {
            switch stance {
            case .walk, .stand: pochiStanding
            case .sit, .phone: pochiSitting
            case .beg: pochiBeg
            case .lie: pochiLying
            }
        }().map(Array.init)
        let hop = stance == .beg && frame % 4 < 2 ? 1 : 0
        let left = Int(foot.x) - 6, top = Int(foot.y) - grid.count - hop

        // Walking: the legs alternate.
        if stance == .walk && frame % 4 < 2 {
            grid[7] = Array("...KWK.KWK...")
            grid[8] = Array("...KKK.KKK...")
        }

        // Shadow on the grass.
        for dx in -4...4 { b.set(Int(foot.x) + dx, Int(foot.y) + 1, PixelBuffer.shade(grass, 0.75)) }

        // Eyes: shut when asleep, half-shut on the phone, blinking now and then.
        let blink = frame % 29 == 0
        if (stance == .lie && pose != .sulking) || stance == .phone || blink {
            for r in grid.indices { for c in grid[r].indices where grid[r][c] == "E" { grid[r][c] = "O" } }
        }
        if pose == .happy { grid[5][3] = "P" } // tongue out

        // Mirrored when heading right: column c is drawn at 12 - c.
        let width = grid[0].count
        func put(_ c: Int, _ y: Int, _ color: UInt32) {
            b.set(left + (walker.facingRight ? width - 1 - c : c), y, color)
        }
        let bob = walker.moving && frame % 2 == 0 ? 1 : 0
        for (r, row) in grid.enumerated() {
            for (c, ch) in row.enumerated() {
                if let color = pochiPalette[ch] { put(c, top + r + (r < 7 ? bob : 0), color) }
            }
        }

        // Tail (on all fours only): wags while walking, a flick now and then when still.
        if stance == .walk || stance == .stand {
            let wag = walker.moving || pose == .happy ? frame % 2 == 0 : frame % 23 < 3 && frame % 2 == 0
            let tailY = top + 2 + bob
            put(11, tailY, 0x2B1D16)
            put(12, tailY - (wag ? 1 : 0), 0xE8913A)
        }

        if stance == .phone {
            // A phone held in both paws, its screen glowing and scrolling.
            // A 4×4 phone over its chest, held by both front paws; the 2×2 screen glows and scrolls.
            for c in 2...5 {
                put(c, top + 5, 0x2B1D16)
                put(c, top + 8, 0x2B1D16)
            }
            for r in 6...7 {
                put(2, top + r, 0x2B1D16)
                put(5, top + r, 0x2B1D16)
            }
            put(1, top + 7, 0xFFF6EA)
            put(6, top + 7, 0xFFF6EA)
            b.glowing = true
            let line = frame % 4 < 2 ? 6 : 7
            for r in 6...7 {
                for c in 3...4 { put(c, top + r, r == line && c == 3 ? 0x5B8FCB : 0xDDF2FF) }
            }
            b.glowing = false
        }

        switch pose {
        case .sleeping:
            // A small "z" drifting up.
            let rise = frame % 12 / 3
            let zx = left + 2, zy = top - 3 - rise
            for (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)] {
                b.set(zx + dx, zy + dy, 0xB8C0D8)
            }
        case .sulking:
            // A little grey cloud raining on it.
            let cx = left + 3, cy = top - 7
            for dx in 1...5 { b.set(cx + dx, cy, 0x8A8F9C) }
            for dx in 0...6 { b.set(cx + dx, cy + 1, 0x8A8F9C) }
            for dx in 1...5 { b.set(cx + dx, cy + 2, 0x6B707C) }
            for (i, dx) in [1, 3, 5].enumerated() {
                b.set(cx + dx, cy + 3 + (frame + i) % 3, 0x8CC0FF)
            }
        case .happy where !walker.moving:
            // A heart floating above.
            let hx = left + 3, hy = top - 5 - frame % 6 / 2
            for (dx, dy) in [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2)] {
                b.set(hx + dx, hy + dy, 0xF46A7A)
            }
        default:
            break
        }
    }

    private static func footprint(_ x: Double, _ y: Double, _ sx: Double, _ sy: Double) -> [CGPoint] {
        [iso.point(x, y, 0), iso.point(x + sx, y, 0), iso.point(x + sx, y + sy, 0), iso.point(x, y + sy, 0)]
    }
}

/// Isometric projection: x goes down-right, y down-left, z up. 1 unit = `unit` pixels.
struct Iso {
    let originX: Double
    let originY: Double
    let unit: Double

    func point(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
        CGPoint(x: originX + (x - y) * unit, y: originY + (x + y) * unit / 2 - z * unit)
    }
}

/// Deterministic pseudo-random numbers, so textures stay the same from frame to frame.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 }

    /// A number in 0..<1.
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}

/// An RGBA pixel buffer with just enough drawing to build blocky isometric scenes.
struct PixelBuffer {
    let width: Int
    let height: Int
    private var pixels: [UInt32]
    /// Pixels that give off their own light (sky, lit window, lamp): `applyLight` leaves them alone.
    private var glow: [Bool]
    /// While true, everything drawn is marked as glowing.
    var glowing = false

    init(width: Int, height: Int, fill: UInt32) {
        self.width = width
        self.height = height
        pixels = Array(repeating: Self.rgba(fill), count: width * height)
        glow = Array(repeating: true, count: width * height)
    }

    /// `hex` is 0xRRGGBB.
    mutating func set(_ x: Int, _ y: Int, _ hex: UInt32) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        pixels[y * width + x] = Self.rgba(hex)
        glow[y * width + x] = glowing
    }

    /// Lights the scene: multiplies every non-glowing pixel by an RGB factor.
    mutating func applyLight(_ light: (r: Double, g: Double, b: Double)) {
        guard light != (1, 1, 1) else { return }
        for i in pixels.indices where !glow[i] {
            let p = pixels[i] // A B G R in memory order
            let r = UInt32(Double(p & 0xFF) * light.r)
            let g = UInt32(Double((p >> 8) & 0xFF) * light.g)
            let b = UInt32(Double((p >> 16) & 0xFF) * light.b)
            pixels[i] = 0xFF00_0000 | (b << 16) | (g << 8) | r
        }
    }

    /// Blends two 0xRRGGBB colours, `t` from 0 (a) to 1 (b).
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let ca = Double((a >> shift) & 0xFF), cb = Double((b >> shift) & 0xFF)
            return UInt32(ca + (cb - ca) * t) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    /// Fills a convex polygon, pixel by pixel (no anti-aliasing: hard pixel-art edges).
    mutating func fill(_ polygon: [CGPoint], _ hex: UInt32) {
        let xs = polygon.map(\.x), ys = polygon.map(\.y)
        let minX = max(0, Int(xs.min()!.rounded(.down))), maxX = min(width - 1, Int(xs.max()!.rounded(.up)))
        let minY = max(0, Int(ys.min()!.rounded(.down))), maxY = min(height - 1, Int(ys.max()!.rounded(.up)))
        guard minX <= maxX, minY <= maxY else { return }
        let color = Self.rgba(hex)
        for py in minY...maxY {
            for px in minX...maxX where Self.contains(polygon, CGPoint(x: Double(px) + 0.5, y: Double(py) + 0.5)) {
                pixels[py * width + px] = color
                glow[py * width + px] = glowing
            }
        }
    }

    /// A one-pixel line (Bresenham), which gives the stepped 2:1 lines of isometric pixel art.
    mutating func line(_ from: CGPoint, _ to: CGPoint, _ hex: UInt32) {
        var x0 = Int(from.x.rounded(.down)), y0 = Int(from.y.rounded(.down))
        let x1 = Int(to.x.rounded(.down)), y1 = Int(to.y.rounded(.down))
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            set(x0, y0, hex)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }

    mutating func outline(_ polygon: [CGPoint], _ hex: UInt32) {
        for i in polygon.indices { line(polygon[i], polygon[(i + 1) % polygon.count], hex) }
    }

    /// A block: top face in `top` (or `color`), the two visible sides shaded darker,
    /// and a dark outline like in pixel art.
    mutating func box(_ iso: Iso, _ x: Double, _ y: Double, _ z: Double,
                      _ sx: Double, _ sy: Double, _ sz: Double,
                      color: UInt32, top: UInt32? = nil, outline: Bool = true) {
        let p = iso.point
        let leftFace = [p(x, y + sy, z), p(x + sx, y + sy, z), p(x + sx, y + sy, z + sz), p(x, y + sy, z + sz)]
        let rightFace = [p(x + sx, y, z), p(x + sx, y + sy, z), p(x + sx, y + sy, z + sz), p(x + sx, y, z + sz)]
        let topFace = [p(x, y, z + sz), p(x + sx, y, z + sz), p(x + sx, y + sy, z + sz), p(x, y + sy, z + sz)]
        fill(leftFace, Self.shade(color, 0.78))
        fill(rightFace, Self.shade(color, 0.6))
        fill(topFace, top ?? color)
        guard outline else { return }
        let edge = Self.shade(color, 0.4)
        // Silhouette, plus the front corner where the two sides meet.
        self.outline([p(x, y, z + sz), p(x + sx, y, z + sz), p(x + sx, y, z), p(x + sx, y + sy, z),
                      p(x, y + sy, z), p(x, y + sy, z + sz)], edge)
        line(p(x + sx, y + sy, z), p(x + sx, y + sy, z + sz), edge)
    }

    /// A one-pixel-wide vertical line, for things too thin to be blocks (poles, posts).
    mutating func verticalLine(_ iso: Iso, _ x: Double, _ y: Double, from z0: Double, to z1: Double, color: UInt32) {
        let bottom = iso.point(x, y, z0), top = iso.point(x, y, z1)
        for py in Int(top.y)...Int(bottom.y) { set(Int(bottom.x), py, color) }
    }

    func cgImage() -> CGImage? {
        var copy = pixels
        return copy.withUnsafeMutableBytes { raw in
            CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
        }
    }

    static func shade(_ hex: UInt32, _ factor: Double) -> UInt32 {
        let r = UInt32(Double((hex >> 16) & 0xFF) * factor)
        let g = UInt32(Double((hex >> 8) & 0xFF) * factor)
        let b = UInt32(Double(hex & 0xFF) * factor)
        return (r << 16) | (g << 8) | b
    }

    /// 0xRRGGBB → the buffer's byte order (R, G, B, A in memory).
    private static func rgba(_ hex: UInt32) -> UInt32 {
        0xFF00_0000 | ((hex & 0xFF) << 16) | (hex & 0xFF00) | ((hex >> 16) & 0xFF)
    }

    private static func contains(_ polygon: [CGPoint], _ point: CGPoint) -> Bool {
        var sign = 0.0
        for i in polygon.indices {
            let a = polygon[i], b = polygon[(i + 1) % polygon.count]
            let cross = (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x)
            if cross == 0 { continue }
            if sign == 0 { sign = cross } else if (cross > 0) != (sign > 0) { return false }
        }
        return true
    }
}
