import SwiftUI

// MARK: - Pixel corgi

/// A loafing corgi drawn from a pixel grid. Breathes, blinks, sleeps when nothing's done, hops when tapped.
struct PixelCorgi: View {
    var sleeping: Bool
    var onTap: () -> Void = {}

    @State private var blink = false
    @State private var breathe = false
    @State private var hop = false

    private static let pixel: CGFloat = 4
    private static let eyes: Set<[Int]> = [[5, 16], [5, 22]] // [row, col]

    // K outline · O fur · W cream · P pink
    private static let art: [String] = [
        "..............KK.......KK.",
        "..............KOK.....KOK.",
        "..............KPOKKKKKOPK.",
        "..............KPOOOWOOOPK.",
        "...KKKKKKKKKKKKOOOOWOOOOK.",
        "..KOOOOOOOOOOOKOKOOWOOKOK.",
        ".KOOOOOOOOOOOOKOOOWWWOOOK.",
        ".KOOOOOOOOOOOOOKOWWKWWOK..",
        ".KOOOOOOOOOOOOOKWWWWWWWK..",
        ".KOOOOOOOOOOOOOOKWWPWWK...",
        ".KWWOOOOOOOOOOOOKWWWKWWWK.",
        "..KKKKKKKKKKKKKKKKKKKKKKK.",
    ]

    private static func color(_ c: Character) -> Color? {
        switch c {
        case "K": Color(red: 0.16, green: 0.09, blue: 0.05)
        case "O": Color(red: 0.89, green: 0.58, blue: 0.29)
        case "W": Color(red: 0.98, green: 0.93, blue: 0.86)
        case "P": Color(red: 0.93, green: 0.55, blue: 0.60)
        default: nil
        }
    }

    var body: some View {
        let p = Self.pixel
        let rows = Self.art.map(Array.init)
        let eyesClosed = sleeping || blink

        Canvas { ctx, _ in
            for (r, line) in rows.enumerated() {
                for (c, ch) in line.enumerated() {
                    let rect = CGRect(x: CGFloat(c) * p, y: CGFloat(r) * p, width: p, height: p)
                    if eyesClosed && Self.eyes.contains([r, c]) {
                        ctx.fill(Path(rect), with: .color(Self.color("O")!))
                        ctx.fill(Path(CGRect(x: rect.minX, y: rect.midY, width: p, height: p * 0.4)),
                                 with: .color(Self.color("K")!))
                    } else if let color = Self.color(ch) {
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .frame(width: CGFloat(rows[0].count) * p, height: CGFloat(rows.count) * p)
        .scaleEffect(x: 1, y: breathe ? 1.035 : 1, anchor: .bottom)
        .offset(y: hop ? -12 : 0)
        .overlay(alignment: .topTrailing) {
            if sleeping { Zzz().offset(x: 6, y: -18) }
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
            withAnimation(.easeInOut(duration: sleeping ? 2.2 : 1.4).repeatForever()) { breathe = true }
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

    func line(nudge: Int) -> String {
        lines[(Self.dayIndex + nudge) % lines.count]
    }

    private static var dayIndex: Int {
        Day.calendar.ordinality(of: .day, in: .year, for: .now) ?? 0
    }

    var verdict: (text: String, color: Color) {
        let pick = { (words: [String]) in words[Self.dayIndex % words.count] }
        return switch self {
        case .empty: (pick(["FANTÔME", "INEXISTANT"]), .gray)
        case .nothing: (pick(["TRAGIQUE", "LARVE", "CANAPÉ"]), Theme.accent)
        case .started: (pick(["LIMACE", "TORTUE", "MOU"]), Theme.accent)
        case .halfway: (pick(["BOF", "PASSABLE", "MOUAIS"]), .orange)
        case .perfect: (pick(["SUSPECT", "MIRACLE", "TOLÉRABLE"]), .green)
        }
    }
}

struct VerdictStamp: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .tracking(2)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 4))
            .rotationEffect(.degrees(-6))
    }
}
