import SwiftUI

// MARK: - Pixel corgi

/// Pochi, the corgi from the portfolio (portfolio/src/components/pochi/PochiSprite.tsx),
/// adapted into one pose per mood.
enum CorgiPose {
    case box, sleeping, phone, sitting, standing, happy
    /// Neglected: curled up, sulking under a little rain cloud.
    case sulking
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

    // The next three poses come from the portfolio (src/components/pochi/PochiSprite.tsx).

    /// Sitting: same head, rounded back down to the rear, hind leg in front.
    static let sit = [
        "..KK......KK............",
        ".KOOK....KOOK...........",
        ".KOPOK..KOPOK...........",
        ".KOPPOKKOPPOK...........",
        "KOOOOOWWOOOOOKK.........",
        "KOOKOOWWOOKOOOOK........",
        "KOOKOWWWWOKOOOOOK.......",
        "KOOWWWNNWWWOOOOOOK......",
        ".KOWWWWWWWWOOOOOOOK.....",
        "..KWWWWWWWKOOOOODOOK....",
        "...KWWWWWWOOOOODOOODK...",
        "...KWWWWWWOOOODOOOODK...",
        "....KWWWWKOOOODOOODDK...",
        "....KWWKSSKOOOOOODDDK...",
        "....KWWKSSKWWWKDDDDK....",
        "....KKKKKKKKKKKKKKKK....",
    ]

    /// Begging: up on its hind legs, front paws folded on its chest. 19 rows, drawn 3 higher.
    static let beg = [
        "..KK......KK............",
        ".KOOK....KOOK...........",
        ".KOPOK..KOPOK...........",
        ".KOPPOKKOPPOK...........",
        "KOOOOOWWOOOOOK..........",
        "KOOKOOWWOOKOOK..........",
        "KOOKOWWWWOKOOK..........",
        "KOOWWWNNWWWOOK..........",
        ".KOWWWWWWWWOOK..........",
        "..KWWWWWWWWOOK..........",
        "KKKWWWWWWWOOOOK.........",
        "KWWKWWWWWWOOOOK.........",
        "KKKKWWWWWWOOOOK.........",
        ".KSSKWWWWWOOOOK.........",
        ".KKKKWWWWOOOODK.........",
        "...KWWWWOOOODDK.........",
        "...KWWWOOOODDDK.........",
        "...KWWKDDDDKWWK.........",
        "..KKKKKK..KKKKK.........",
    ]
    static let begRise = 3

    /// Napping: lying down, head on its front paws, eyes shut (drawn in the grid).
    static let nap = [
        "..KK......KK............",
        ".KOOK....KOOK...........",
        ".KOPOK..KOPOK...........",
        ".KOPPOKKOPPOK...........",
        "KOOOOOWWOOOOOKKKKKKKK...",
        "KOOOOOWWOOOOOOOOOOOOOK..",
        "KOOKOWWWWOKOOOOOOOOOOOK.",
        "KOOWWWNNWWWOOOOOOOOOODDK",
        ".KOWWWWWWWWOOOOOOOOODDDK",
        "KWWWKWWWWKWWWWWWWWWDDDK.",
        "KKKKKKKKKKKKKKKKKKKKKKK.",
    ]
    /// Breathing in: the back rises by one pixel.
    static let breath = (14...20).map { Pixel(x: $0, y: 3, c: "K") } + (14...20).map { Pixel(x: $0, y: 4, c: "O") }

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

    var pixel: CGFloat = 3
    /// 30 × 19: Pochi is 24 wide, the extra room in front of it is for the phone,
    /// and the top 3 rows are for when it stands up on its hind legs.
    private static let width = 30
    private static let height = 19
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
        case .sulking:
            return [Layer(grid: Pochi.nap, y: 5)]
        case .sleeping:
            var layers = [Layer(grid: Pochi.nap, y: 5)]
            if (tick / 14) % 2 == 0 { layers.append(Layer(pixels: Pochi.breath, y: 5)) }
            return layers
        case .sitting:
            var layers = [Layer(grid: Pochi.sit)]
            if excited { layers.append(Layer(pixels: Pochi.tongue)) }
            if eyesClosed { layers.append(Layer(pixels: Pochi.blink)) }
            return layers
        case .happy:
            let y = -Pochi.begRise
            return [Layer(grid: Pochi.beg, y: y), Layer(pixels: Pochi.tongue, y: y)]
                + (eyesClosed ? [Layer(pixels: Pochi.blink, y: y)] : [])
        case .standing:
            var layers: [Layer] = []
            if tailUp { layers.append(Layer(pixels: Pochi.tail)) }
            layers.append(Layer(grid: Pochi.standing))
            if excited { layers.append(Layer(pixels: Pochi.tongue)) }
            if eyesClosed { layers.append(Layer(pixels: Pochi.blink)) }
            return layers
        }
    }

    var body: some View {
        let p = pixel
        // Pushed against the right edge, next to the speech bubble.
        let shift = 6
        let layers = layers.map { Layer(grid: $0.grid, pixels: $0.pixels, x: $0.x + shift, y: $0.y + Pochi.begRise) }
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
                let center = CGPoint(x: 18 * p, y: 12 * p)
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
        .frame(width: CGFloat(Self.width) * p, height: CGFloat(Self.height) * p)
        .offset(y: hop ? -p : 0)
        .overlay(alignment: .topLeading) {
            switch pose {
            case .sleeping: Zzz().offset(x: 20 * p, y: 4 * p)
            case .sulking: RainCloud(pixel: p).offset(x: 6 * p, y: 0)
            case .happy: Hearts().offset(x: 12 * p, y: -p)
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

/// A small grey cloud with rain falling, over a sulking Pochi.
private struct RainCloud: View {
    let pixel: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.15)) { timeline in
            let frame = Int(timeline.date.timeIntervalSinceReferenceDate / 0.15)
            Canvas { ctx, _ in
                let p = pixel
                func px(_ x: Int, _ y: Int, _ color: Color) {
                    ctx.fill(Path(CGRect(x: CGFloat(x) * p, y: CGFloat(y) * p, width: p + 0.1, height: p + 0.1)),
                             with: .color(color))
                }
                let cloud = Color(white: 0.55), dark = Color(white: 0.4)
                for x in 3...8 { px(x, 0, cloud) }
                for x in 1...10 { px(x, 1, cloud) }
                for x in 0...11 { px(x, 2, cloud) }
                for x in 1...10 { px(x, 3, dark) }
                // Drops falling in staggered columns.
                for (i, x) in [2, 5, 8, 10].enumerated() {
                    let y = 5 + (frame + i * 2) % 5
                    px(x, y, Color(red: 0.55, green: 0.75, blue: 1))
                }
            }
            .frame(width: 12 * pixel, height: 10 * pixel)
        }
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
        .padding(.leading, PixelFrame.tailWidth() + 14)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(PixelFrame(tail: true).fill(Self.fill))
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
            // Doomscrolling by day, asleep at night.
            let hour = Day.calendar.component(.hour, from: .now)
            return hour >= 22 || hour < 7 ? .sleeping : .phone
        case .started: return .sitting
        case .halfway: return .standing
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
        (.box, "BOX"), (.sleeping, "SLEEPING"), (.phone, "PHONE"), (.sitting, "SITTING"), (.sulking, "SULKING"), (.standing, "STANDING"), (.happy, "HAPPY"),
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
