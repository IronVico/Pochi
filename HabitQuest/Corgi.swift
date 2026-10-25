import SwiftUI

// MARK: - Pixel corgi

enum CorgiPose {
    case box, sleeping, lying, sitting, happy
}

/// A sprite placed on the corgi's 26×18 pixel canvas.
private struct Layer {
    let sprite: [String]
    let x: Int
    let y: Int
}

/// K outline · O fur · W cream · P pink · E eye · B/D cardboard.
private enum Sprites {
    static let loaf = [
        "..............KK.......KK.",
        "..............KOK.....KOK.",
        "..............KPOKKKKKOPK.",
        "..............KPOOOWOOOPK.",
        "...KKKKKKKKKKKKOOOOWOOOOK.",
        "..KOOOOOOOOOOOKOEOOWOOEOK.",
        ".KOOOOOOOOOOOOKOOOWWWOOOK.",
        ".KOOOOOOOOOOOOOKOWWKWWOK..",
        ".KOOOOOOOOOOOOOKWWWWWWWK..",
        ".KOOOOOOOOOOOOOOKWWPWWK...",
        ".KWWOOOOOOOOOOOOKWWWKWWWK.",
        "..KKKKKKKKKKKKKKKKKKKKKKK.",
    ]

    static let head = [
        "KK.......KK",
        "KOK.....KOK",
        "KPOKKKKKOPK",
        "KPOOOWOOOPK",
        "KOOOOWOOOOK",
        "KOEOOWOOEOK",
        "KOOOWWWOOOK",
        ".KOWWKWWOK.",
        ".KWWWWWWWK.",
        "..KWWPWWK..",
    ]

    static let sittingBody = [
        "..KOOWWWWWOOK...",
        ".KOOOWWWWWOOOK..",
        ".KOOOWWWWWOOOK..",
        ".KOOOWWWWWOOOOK.",
        ".KOOKWWKWWKOOOK.",
        ".KOOKWWKWWKOOOK.",
        ".KOOKWWKWWKOOOK.",
        ".KKKKKKKKKKKKKK.",
    ]

    static let box = [
        "KKKKKKKKKKKKKKKK",
        "KBBBBBBDDBBBBBBK",
        "KBBBBBBDDBBBBBBK",
        "KBBBBBBDDBBBBBBK",
        "KBBBBBBBBBBBBBBK",
        "KBBBBBBBBBBBBBBK",
        "KDDDDDDDDDDDDDDK",
        "KKKKKKKKKKKKKKKK",
    ]
    static let leftFlap = ["BK.", "KBK", ".KB"]
    static let rightFlap = [".KB", "KBK", "BK."]

    static let tongue = ["P", "P"]
    static let blush = ["P"]
}

/// A pixel-art corgi whose pose and animation follow your day. Tap it to make it hop.
struct PixelCorgi: View {
    let pose: CorgiPose
    var onTap: () -> Void = {}

    @State private var tick = 0
    @State private var blink = false
    @State private var breathe = false
    @State private var bounce = false
    @State private var hop = false

    private static let pixel: CGFloat = 4
    private static let size = (width: 26, height: 18)

    private var layers: [Layer] {
        switch pose {
        case .sleeping, .lying:
            return [Layer(sprite: Sprites.loaf, x: 0, y: 6)]
        case .sitting, .happy:
            var layers = [
                Layer(sprite: Sprites.sittingBody, x: 5, y: 10),
                Layer(sprite: Sprites.head, x: 7, y: 0),
            ]
            if tick % 2 == 0 { layers.append(Layer(sprite: Sprites.tongue, x: 12, y: 10)) }
            if pose == .happy {
                layers.append(Layer(sprite: Sprites.blush, x: 8, y: 6))
                layers.append(Layer(sprite: Sprites.blush, x: 16, y: 6))
            }
            return layers
        case .box:
            // Peeks out, then ducks back in every few seconds.
            let peek = (tick / 5) % 3 == 2 ? 2 : 0
            return [
                Layer(sprite: Sprites.head, x: 7, y: 2 + peek),
                Layer(sprite: Sprites.box, x: 5, y: 10),
                Layer(sprite: Sprites.leftFlap, x: 2, y: 7),
                Layer(sprite: Sprites.rightFlap, x: 21, y: 7),
            ]
        }
    }

    private static func color(_ c: Character) -> Color? {
        switch c {
        case "K", "E": Color(red: 0.16, green: 0.09, blue: 0.05)
        case "O": Color(red: 0.89, green: 0.58, blue: 0.29)
        case "W": Color(red: 0.98, green: 0.93, blue: 0.86)
        case "P": Color(red: 0.93, green: 0.55, blue: 0.60)
        case "B": Color(red: 0.78, green: 0.57, blue: 0.35)
        case "D": Color(red: 0.55, green: 0.36, blue: 0.19)
        default: nil
        }
    }

    var body: some View {
        let p = Self.pixel
        let layers = layers
        let eyesClosed = pose == .sleeping || blink

        Canvas { ctx, _ in
            for layer in layers {
                for (r, line) in layer.sprite.enumerated() {
                    for (c, ch) in line.enumerated() {
                        let rect = CGRect(x: CGFloat(layer.x + c) * p, y: CGFloat(layer.y + r) * p, width: p, height: p)
                        if ch == "E" && eyesClosed {
                            ctx.fill(Path(rect), with: .color(Self.color("O")!))
                            ctx.fill(Path(CGRect(x: rect.minX, y: rect.midY, width: p, height: p * 0.4)),
                                     with: .color(Self.color("K")!))
                        } else if let color = Self.color(ch) {
                            ctx.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            }
        }
        .frame(width: CGFloat(Self.size.width) * p, height: CGFloat(Self.size.height) * p)
        .scaleEffect(x: 1, y: breathe ? 1.04 : 1, anchor: .bottom)
        .offset(y: (bounce ? -7 : 0) + (hop ? -12 : 0))
        .overlay(alignment: .topTrailing) {
            switch pose {
            case .sleeping: Zzz().offset(x: 2, y: 4)
            case .happy: Hearts().offset(x: -14, y: 0)
            default: EmptyView()
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { hop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { hop = false }
            }
            onTap()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hop) { _, new in new }
        .onAppear {
            switch pose {
            case .sleeping, .lying:
                withAnimation(.easeInOut(duration: pose == .sleeping ? 2.2 : 1.4).repeatForever()) { breathe = true }
            case .happy:
                withAnimation(.easeOut(duration: 0.32).repeatForever()) { bounce = true }
            case .sitting, .box:
                break
            }
        }
        .task {
            // Animation frames: panting, peeking.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(pose == .happy ? 200 : 320))
                tick += 1
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(.random(in: 2.5...5)))
                blink = true
                try? await Task.sleep(for: .milliseconds(140))
                blink = false
            }
        }
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

/// Monospaced bubble that types its text out.
struct SpeechBubble: View {
    let text: String
    @State private var shown = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text).hidden()
            Text(text.prefix(shown))
        }
        .font(.system(size: 16, weight: .regular, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.12), in: .rect(cornerRadius: 20))
        .task(id: text) {
            shown = 0
            for i in 1...max(text.count, 1) {
                try? await Task.sleep(for: .milliseconds(25))
                shown = i
            }
        }
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
        case .empty: .box
        case .nothing: .sleeping
        case .started: .lying
        case .halfway: .sitting
        case .perfect: .happy
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
        (.box, "BOX"), (.sleeping, "SLEEPING"), (.lying, "LYING"), (.sitting, "SITTING"), (.happy, "HAPPY"),
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
