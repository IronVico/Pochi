import SwiftUI

// MARK: - Pixel corgi

/// Pochi, the corgi from the portfolio (portfolio/src/components/pochi/PochiSprite.tsx),
/// adapted into one pose per mood.
enum CorgiPose {
    case box, sleeping, phone, lying, standing, happy
}

private struct Pixel {
    let x: Int
    let y: Int
    let c: Character
}

private enum Pochi {
    static let palette: [Character: Color] = [
        "K": Color(hex: 0x2B1D16), // outline
        "O": Color(hex: 0xE8913A), // red fur
        "D": Color(hex: 0xC46F2A), // fur shadow
        "W": Color(hex: 0xFFF6EA), // white (blaze, muzzle, chest, socks)
        "P": Color(hex: 0xF4A3A3), // inner ears, tongue
        "N": Color(hex: 0x120C09), // nose
        "S": Color(hex: 0xE6D6C3), // far-side socks, in shadow
        "C": Color(hex: 0xC8925A), // cardboard
        "X": Color(hex: 0x8C5C30), // cardboard shadow
        "L": Color(hex: 0xBFE3FF), // phone screen
        "M": Color(hex: 0x5B8FCB), // lines on the screen
    ]

    // 24 × 16, head three-quarters to the left, body in profile, short legs.
    static let standing = [
        "..KK......KK............",
        ".KOOK....KOOK...........",
        ".KOPOK..KOPOK...........",
        ".KOPPOKKOPPOK...........",
        "KOOOOOWWOOOOOKKKKKKKKK..",
        "KOOKOOWWOOKOOOOOOOOOOOK.",
        "KOOKOWWWWOKOOOOOOOOOOOOK",
        "KOOWWWNNWWWOOOOOOOOOOOOK",
        ".KOWWWWWWWWOOOOOOOOOOODK",
        "..KWWWWWWWKOOOOOOOOOOODK",
        "...KWWWWWWOOOOOOOOOOODDK",
        "...KWWWWWWWOOOOOOOOODDK.",
        "....KWWWWWWWWWWWWWWWWDK.",
        "....KWWKSSKKKKKKKWWKSSK.",
        "....KWWKSSK.....KWWKSSK.",
        "....KKKKKKK.....KKKKKKK.",
    ]

    /// Same Pochi with the legs tucked under: belly on the floor.
    static let lying = Array(standing.prefix(13)) + ["....KKKKKKKKKKKKKKKKKKK."]

    /// Sitting upright, three-quarters: big head, small body, tail plume on the side.
    static let sitting = [
        "..KK......KK....",
        ".KOOK....KOOK...",
        ".KOPOK..KOPOK...",
        ".KOPPOKKOPPOK...",
        "KOOOOOWWOOOOK...",
        "KOOKOOWWOOKOK...",
        "KOOKOWWWWOKOK...",
        "KOOWWWNNWWWOK...",
        ".KOWWWWWWWWK....",
        "..KWWWWWWWKOK.KK",
        "..KWWWWWWWOOOKOK",
        "..KWWWWWWOOOOOOK",
        "..KWWKWWWOOOODK.",
        "..KWWKWWKOOODDK.",
        "..KWWKWWKWWWDK..",
        "..KKKKKKKKKKKK..",
    ]

    /// Just the head, closed on the right, to peek out of the box.
    static let head = [
        "..KK......KK.",
        ".KOOK....KOOK",
        ".KOPOK..KOPOK",
        ".KOPPOKKOPPOK",
        "KOOOOOWWOOOOK",
        "KOOKOOWWOOKOK",
        "KOOKOWWWWOKOK",
        "KOOWWWNNWWWOK",
        ".KOWWWWWWWWK.",
        "..KWWWWWWWK..",
    ]

    static let box = [
        "KKKKKKKKKKKKKKKK",
        "KCCCCCCXXCCCCCCK",
        "KCCCCCCXXCCCCCCK",
        "KCCCCCCXXCCCCCCK",
        "KCCCCCCCCCCCCCCK",
        "KXXXXXXXXXXXXXXK",
        "KKKKKKKKKKKKKKKK",
    ]
    static let leftFlap = ["CK.", "KCK", ".KC"]
    static let rightFlap = [".KC", "KCK", "CK."]

    /// Phone outline; the screen inside is drawn per frame so it scrolls.
    static let phone = [
        "KKKK",
        "K..K",
        "K..K",
        "K..K",
        "KKKK",
    ]

    /// Closed eyelids: the 2-px eyes turn back to fur, a line stays at the bottom.
    static let blink = [Pixel(x: 3, y: 5, c: "O"), Pixel(x: 10, y: 5, c: "O")]
    /// Open mouth under the nose, pink tongue.
    static let tongue = [Pixel(x: 6, y: 8, c: "P"), Pixel(x: 7, y: 8, c: "P"), Pixel(x: 7, y: 9, c: "P")]
    /// Tail plume, flashed on and off to wag.
    static let tail = [
        Pixel(x: 22, y: 2, c: "K"), Pixel(x: 23, y: 2, c: "K"), Pixel(x: 21, y: 3, c: "K"),
        Pixel(x: 22, y: 3, c: "O"), Pixel(x: 23, y: 3, c: "K"), Pixel(x: 22, y: 4, c: "O"),
        Pixel(x: 23, y: 4, c: "K"),
    ]
}

/// A drawable piece placed on the canvas: a grid, or loose pixels.
private struct Layer {
    var grid: [String] = []
    var pixels: [Pixel] = []
    var x = 0
    var y = 0
}

/// Pochi, whose pose follows your day. Frame-by-frame animation, in the spirit of a sprite.
/// Tap it and it gets happy for a moment.
struct PixelCorgi: View {
    let pose: CorgiPose
    var onTap: () -> Void = {}

    @State private var tick = 0 // ~14 fps
    @State private var blink = false
    @State private var excitedUntil = Date.distantPast

    private static let pixel: CGFloat = 3
    /// 30 × 16: Pochi is 24 wide, the extra room in front of it is for the phone.
    private static let width = 30
    private static let frame: Duration = .milliseconds(70)

    private var excited: Bool { pose == .happy || excitedUntil > .now }

    private var layers: [Layer] {
        let eyesClosed = pose == .sleeping || blink
        // Idle: two quick flicks every ~3.6 s. Excited: steady wag.
        let idleFlick = [41, 42, 45, 46].contains(tick % 51)
        let tailUp = excited ? (tick / 2) % 2 == 0 : idleFlick

        switch pose {
        case .box:
            let peek = (tick / 25) % 3 == 2 ? 2 : 0
            var layers = [Layer(grid: Pochi.head, x: 5, y: 1 + peek)]
            if eyesClosed { layers.append(Layer(pixels: Pochi.blink, x: 5, y: 1 + peek)) }
            if excited { layers.append(Layer(pixels: Pochi.tongue, x: 5, y: 1 + peek)) }
            layers += [
                Layer(grid: Pochi.box, x: 4, y: 9),
                Layer(grid: Pochi.leftFlap, x: 1, y: 6),
                Layer(grid: Pochi.rightFlap, x: 20, y: 6),
            ]
            return layers
        case .phone:
            // Sitting up, phone held in both front paws, half-closed eyes looking down at it.
            let scroll = (tick / 5) % 4
            var screen: [Pixel] = []
            for row in 0..<3 {
                let line = (row + scroll) % 2 == 0
                for col in 0..<2 { screen.append(Pixel(x: col, y: row, c: line && col == 0 ? "M" : "L")) }
            }
            let paws = [Pixel(x: 2, y: 12, c: "W"), Pixel(x: 7, y: 12, c: "W"),
                        Pixel(x: 2, y: 13, c: "K"), Pixel(x: 7, y: 13, c: "K")]
            return [
                Layer(grid: Pochi.sitting, x: 7, y: 0),
                Layer(pixels: Pochi.blink, x: 7, y: 0),
                Layer(grid: Pochi.phone, x: 10, y: 10),
                Layer(pixels: screen, x: 11, y: 11),
                Layer(pixels: paws, x: 7, y: 0),
            ]
        case .sleeping, .lying, .standing, .happy:
            let standing = pose == .standing || pose == .happy
            let y = standing ? 0 : 2
            var layers: [Layer] = []
            if tailUp && pose != .sleeping { layers.append(Layer(pixels: Pochi.tail, y: y)) }
            layers.append(Layer(grid: standing ? Pochi.standing : Pochi.lying, y: y))
            if excited { layers.append(Layer(pixels: Pochi.tongue, y: y)) }
            if eyesClosed { layers.append(Layer(pixels: Pochi.blink, y: y)) }
            return layers
        }
    }

    var body: some View {
        let p = Self.pixel
        // Pushed against the right edge, next to the speech bubble.
        let shift = 6
        let layers = layers.map { Layer(grid: $0.grid, pixels: $0.pixels, x: $0.x + shift, y: $0.y) }
        let hop = excited && pose != .box && (tick / 3) % 2 == 0

        Canvas { ctx, _ in
            func fill(_ x: Int, _ y: Int, _ c: Character) {
                guard let color = Pochi.palette[c] else { return }
                // A hair over 1 px so neighbours never leave a seam.
                ctx.fill(Path(CGRect(x: CGFloat(x) * p, y: CGFloat(y) * p, width: p + 0.1, height: p + 0.1)),
                         with: .color(color))
            }
            if pose == .phone {
                // Blue glow of the screen on Pochi's face.
                let center = CGPoint(x: 18 * p, y: 9 * p)
                ctx.fill(Path(ellipseIn: CGRect(x: center.x - 6 * p, y: center.y - 6 * p, width: 12 * p, height: 12 * p)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0x7CC4FF).opacity(0.4), .clear]),
                                               center: center, startRadius: 0, endRadius: 6 * p))
            }
            for layer in layers {
                for (r, line) in layer.grid.enumerated() {
                    for (c, ch) in line.enumerated() { fill(layer.x + c, layer.y + r, ch) }
                }
                for px in layer.pixels { fill(layer.x + px.x, layer.y + px.y, px.c) }
            }
        }
        .frame(width: CGFloat(Self.width) * p, height: 16 * p)
        .offset(y: hop ? -p : 0)
        .overlay(alignment: .topLeading) {
            switch pose {
            case .sleeping: Zzz().offset(x: 20 * p, y: -2 * p)
            case .happy: Hearts().offset(x: 12 * p, y: -p)
            default: EmptyView()
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            excitedUntil = .now.addingTimeInterval(1.5)
            onTap()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: excitedUntil)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.frame)
                tick += 1
            }
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

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private struct Zzz: View {
    var body: some View {
        PhaseAnimator([0, 1, 2]) { phase in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<3) { i in
                    Text("z")
                        .font(.system(size: CGFloat(10 + i * 4), weight: .bold, design: .monospaced))
                        .opacity(i <= phase ? 0.8 : 0)
                        .offset(y: CGFloat(-i * 6))
                }
            }
            .foregroundStyle(.secondary)
        } animation: { _ in .easeInOut(duration: 0.6) }
    }
}

/// Little hearts drifting up.
private struct Hearts: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3) { i in
                    let progress = (t / 1.8 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8 + CGFloat(i) * 2))
                        .foregroundStyle(Color(red: 0.93, green: 0.45, blue: 0.55))
                        .offset(x: CGFloat(i - 1) * 12 + sin(progress * .pi * 2) * 3, y: -progress * 34)
                        .opacity(1 - progress)
                }
            }
        }
    }
}

// MARK: - Speech bubble

/// Pixel-art dialogue bubble: stepped corners, a tail pointing at Pochi, a name tag,
/// and a line typed out with a cursor. The bubble hugs its text, but the space it sits in
/// is always 3 lines high so the screen below never moves.
struct SpeechBubble: View {
    let text: String
    @State private var shown = 0

    private static let font = Font.system(size: 15, weight: .regular, design: .monospaced)
    private static let fill = Color(white: 0.13)

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
            Text("POCHI")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Theme.accent)
            content()
                .font(Self.font)
                .foregroundStyle(.white)
        }
        .padding(.leading, PixelBubble.tail + 14)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(PixelBubble().fill(Self.fill))
    }
}

/// A rectangle with stepped pixel corners and a stepped tail on the left.
struct PixelBubble: Shape {
    static let unit: CGFloat = 3
    static var tail: CGFloat { unit * 3 }

    func path(in rect: CGRect) -> Path {
        let u = Self.unit
        let l = rect.minX + Self.tail, r = rect.maxX, t = rect.minY, b = rect.maxY
        let cy = (rect.minY + rect.maxY) / 2
        var p = Path()
        p.move(to: CGPoint(x: l + 2 * u, y: t))
        p.addLines([
            // Top-right corner
            CGPoint(x: r - 2 * u, y: t), CGPoint(x: r - 2 * u, y: t + u), CGPoint(x: r - u, y: t + u),
            CGPoint(x: r - u, y: t + 2 * u), CGPoint(x: r, y: t + 2 * u),
            // Bottom-right corner
            CGPoint(x: r, y: b - 2 * u), CGPoint(x: r - u, y: b - 2 * u), CGPoint(x: r - u, y: b - u),
            CGPoint(x: r - 2 * u, y: b - u), CGPoint(x: r - 2 * u, y: b),
            // Bottom-left corner
            CGPoint(x: l + 2 * u, y: b), CGPoint(x: l + 2 * u, y: b - u), CGPoint(x: l + u, y: b - u),
            CGPoint(x: l + u, y: b - 2 * u), CGPoint(x: l, y: b - 2 * u),
            // Tail, stepping out towards Pochi
            CGPoint(x: l, y: cy + 2 * u), CGPoint(x: l - 3 * u, y: cy + 2 * u), CGPoint(x: l - 3 * u, y: cy + u),
            CGPoint(x: l - 2 * u, y: cy + u), CGPoint(x: l - 2 * u, y: cy), CGPoint(x: l - u, y: cy),
            CGPoint(x: l - u, y: cy - u), CGPoint(x: l, y: cy - u),
            // Top-left corner
            CGPoint(x: l, y: t + 2 * u), CGPoint(x: l + u, y: t + 2 * u), CGPoint(x: l + u, y: t + u),
            CGPoint(x: l + 2 * u, y: t + u),
        ])
        p.closeSubpath()
        return p
    }
}

// MARK: - Mood

enum CorgiMood {
    case empty, nothing, started, halfway, perfect

    init(stats: GameStats) {
        if stats.habitCount == 0 { self = .empty; return }
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
            // Doomscrolling by day, asleep at night.
            let hour = Day.calendar.component(.hour, from: .now)
            return hour >= 22 || hour < 7 ? .sleeping : .phone
        case .started: return .lying
        case .halfway: return .standing
        case .perfect: return .happy
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
        (.box, "BOX"), (.sleeping, "SLEEPING"), (.phone, "PHONE"), (.lying, "LYING"), (.standing, "STANDING"), (.happy, "HAPPY"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                ForEach(poses, id: \.1) { pose, name in
                    HStack(spacing: 20) {
                        PixelCorgi(pose: pose)
                        Text(name).font(Theme.mono(16)).tracking(2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(30)
            .padding(.top, 40)
        }
        .background(Color.black)
    }
}
#endif
