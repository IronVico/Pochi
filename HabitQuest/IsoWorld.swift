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
        case standing, lying, sleeping, phone, happy
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

    static func render(level: Int, trees: Int, pochi: Pochi, frame: Int) -> CGImage? {
        var b = PixelBuffer(width: width, height: height, fill: 0x141826)

        // Stars, a few of them twinkling.
        let stars = [(6, 5), (18, 12), (34, 3), (84, 6), (97, 17), (72, 2), (9, 26), (99, 33), (4, 44), (49, 7)]
        for (i, star) in stars.enumerated() {
            let bright = (frame / 3 + i * 7) % 11 == 0
            b.set(star.0, star.1, bright ? 0xC8D0F0 : 0x4A5270)
        }

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
            items.append((5.6, { house(&$0, level: level, frame: frame) }))
        }
        if level >= 5 {
            items.append((8.4, { $0.box(iso, 4.3, 3.8, 0, 0.5, 0.5, 0.18, color: 0x4FA3FF, top: 0x9FD3FF) }))
        }
        if level >= 8 {
            items.append((5.9, {
                $0.verticalLine(iso, 1.47, 4.57, from: 0, to: 1.4, color: 0x3A3A3A)
                $0.box(iso, 1.32, 4.42, 1.4, 0.3, 0.3, 0.3, color: frame % 6 < 5 ? 0xFFD15C : 0xFFE9A0)
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
        items.append((8.5, { drawPochi(&$0, pochi, frame: frame) }))

        for item in items.sorted(by: { $0.depth < $1.depth }) {
            item.draw(&b)
        }
        return b.cgImage()
    }

    // MARK: - Pieces

    private static func island(_ b: inout PixelBuffer) {
        b.box(iso, 0, 0, -1.5, 6, 6, 1.2, color: dirt)
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

    private static func house(_ b: inout PixelBuffer, level: Int, frame: Int) {
        b.box(iso, 1.9, 1.5, 0, 2.2, 2.2, 0.25, color: 0xB8B8B8)
        guard level >= 3 else { return }

        b.box(iso, 2, 1.6, 0.25, 2, 2, 1.5, color: wood)
        // Planks.
        for z in [0.65, 1.05, 1.45] {
            b.line(iso.point(2, 3.6, z), iso.point(4, 3.6, z), PixelBuffer.shade(wood, 0.62))
            b.line(iso.point(4, 1.6, z), iso.point(4, 3.6, z), PixelBuffer.shade(wood, 0.48))
        }
        // Door with its frame, and a doormat; lit window on the right.
        b.fill([iso.point(2.6, 3.6, 0.25), iso.point(3.4, 3.6, 0.25),
                iso.point(3.4, 3.6, 1.35), iso.point(2.6, 3.6, 1.35)], PixelBuffer.shade(wood, 0.45))
        b.fill([iso.point(2.7, 3.6, 0.25), iso.point(3.3, 3.6, 0.25),
                iso.point(3.3, 3.6, 1.25), iso.point(2.7, 3.6, 1.25)], 0x2A180C)
        b.fill([iso.point(2.65, 3.7, 0.01), iso.point(3.35, 3.7, 0.01),
                iso.point(3.35, 4.1, 0.01), iso.point(2.65, 4.1, 0.01)], 0xC0453F)
        b.fill([iso.point(4, 2.25, 0.8), iso.point(4, 2.95, 0.8),
                iso.point(4, 2.95, 1.4), iso.point(4, 2.25, 1.4)], PixelBuffer.shade(wood, 0.4))
        b.fill([iso.point(4, 2.35, 0.88), iso.point(4, 2.85, 0.88),
                iso.point(4, 2.85, 1.32), iso.point(4, 2.35, 1.32)], 0xFFD15C)
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
    private static let pochiLying = [
        ".K...K.......",
        "KPK.KPK......",
        "KOOOOOKKKKK..",
        "KOEOEOOOOOOK.",
        "KWWNWWOOOOOK.",
        ".KWWWWOOOODK.",
        "..KKKKKKKKK..",
    ]

    /// Where Pochi stands: right of the doghouse, bowl in front of its nose.
    private static let pochiSpot = (x: 5.2, y: 3.3)

    private static func drawPochi(_ b: inout PixelBuffer, _ pose: Pochi, frame: Int) {
        let foot = iso.point(pochiSpot.x, pochiSpot.y, 0)
        let lying = pose == .lying || pose == .sleeping || pose == .phone
        var grid = (lying ? pochiLying : pochiStanding).map(Array.init)
        let hop = pose == .happy && frame % 4 < 2 ? 1 : 0
        let left = Int(foot.x) - 6, top = Int(foot.y) - grid.count - hop

        // Shadow on the grass.
        for dx in -4...4 { b.set(Int(foot.x) + dx, Int(foot.y) + 1, PixelBuffer.shade(grass, 0.75)) }

        // Eyes: shut when asleep, half-shut on the phone, blinking now and then.
        let blink = frame % 29 == 0
        if pose == .sleeping || pose == .phone || blink {
            for r in grid.indices { for c in grid[r].indices where grid[r][c] == "E" { grid[r][c] = "O" } }
        }
        if pose == .happy { grid[5][3] = "P" }

        for (r, row) in grid.enumerated() {
            for (c, ch) in row.enumerated() {
                if let color = pochiPalette[ch] { b.set(left + c, top + r, color) }
            }
        }

        // Tail: a flick now and then, a steady wag when happy, still when asleep.
        let wag = pose == .happy ? frame % 2 == 0 : (pose != .sleeping && frame % 23 < 3 && frame % 2 == 0)
        let tailY = top + 2
        b.set(left + 11, tailY, 0x2B1D16)
        b.set(left + 12, tailY - (wag ? 1 : 0), 0xE8913A)

        switch pose {
        case .sleeping:
            // A small "z" drifting up.
            let rise = frame % 12 / 3
            let zx = left + 2, zy = top - 3 - rise
            for (dx, dy) in [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)] {
                b.set(zx + dx, zy + dy, 0xB8C0D8)
            }
        case .phone:
            // A glowing phone in front of its paws.
            b.set(left - 1, top + 4, 0x2B1D16)
            b.set(left - 1, top + 5, 0x2B1D16)
            b.set(left - 2, top + 4, 0x9FD3FF)
            b.set(left - 2, top + 5, frame % 4 < 2 ? 0x9FD3FF : 0x5B8FCB)
        case .happy:
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

    init(width: Int, height: Int, fill: UInt32) {
        self.width = width
        self.height = height
        pixels = Array(repeating: Self.rgba(fill), count: width * height)
    }

    /// `hex` is 0xRRGGBB.
    mutating func set(_ x: Int, _ y: Int, _ hex: UInt32) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        pixels[y * width + x] = Self.rgba(hex)
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
