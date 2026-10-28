import SwiftUI

/// An SF Symbol drawn as a sticker: a pastel fill under its bold ink outline.
/// Symbols with no `.fill` variant take `fill: nil` and are drawn in ink.
struct Doodle: View {
    let symbol: String
    var fill: Color?
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            if let fill { Image(systemName: symbol + ".fill").foregroundStyle(fill) }
            Image(systemName: symbol).foregroundStyle(Theme.ink)
        }
        .font(.system(size: size, weight: .bold))
    }
}

/// A dog bone, for Pochi's food gauge (SF Symbols has none).
struct BoneDoodle: View {
    var fill: Color = Theme.card
    var size: CGFloat = 18

    var body: some View {
        let bone = Self.bone
        Canvas { ctx, canvas in
            ctx.scaleBy(x: canvas.width / 24, y: canvas.height / 24)
            ctx.fill(bone, with: .color(fill))
            ctx.stroke(bone, with: .color(Theme.ink), lineWidth: 2.2)
        }
        .frame(width: size * 1.15, height: size * 1.15)
    }

    /// Bone in a 24 × 24 box: a bar with two knobs at each end, tilted 45°.
    private static let bone: Path = {
        var shape = Path(roundedRect: CGRect(x: 5, y: 9.5, width: 14, height: 5), cornerRadius: 1)
        for (x, y) in [(5.0, 9.0), (5.0, 15.0), (19.0, 9.0), (19.0, 15.0)] {
            shape = shape.union(Path(ellipseIn: CGRect(x: x - 3.2, y: y - 3.2, width: 6.4, height: 6.4)))
        }
        return shape.applying(CGAffineTransform(translationX: 12, y: 12).rotated(by: -.pi / 4).translatedBy(x: -12, y: -12))
    }()
}

/// Habits still store an emoji, so nothing changes in the data: each emoji the editor
/// offers maps to a doodle, and anything else is shown as the emoji itself.
enum HabitDoodle {
    /// Icons offered when creating a habit.
    static let habitIcons = ["💧", "🏃", "📚", "🧘", "💪", "🍎", "😴", "✍️",
                             "🎸", "🧹", "💊", "📵", "🦷", "🌱", "💰", "🎯"]

    /// SF Symbol for each emoji, and whether it has a `.fill` variant to colour in.
    static let symbols: [String: (name: String, fills: Bool)] = [
        "💧": ("drop", true), "🏃": ("figure.run", false), "📚": ("books.vertical", false),
        "🧘": ("figure.mind.and.body", false), "💪": ("dumbbell", true), "🍎": ("carrot", true),
        "😴": ("moon.zzz", true), "✍️": ("pencil.and.scribble", false), "🎸": ("guitars", true),
        "🧹": ("bubbles.and.sparkles", false), "💊": ("pills", true), "📵": ("iphone.slash", false),
        "🦷": ("mouth", true), "🌱": ("leaf", true), "💰": ("banknote", false), "🎯": ("target", false),
    ]
}

/// A habit's icon: its doodle coloured in when there is one, the emoji otherwise.
struct EmojiIcon: View {
    let emoji: String
    var size: CGFloat = 28
    var fill = Theme.card

    var body: some View {
        if let symbol = HabitDoodle.symbols[emoji] {
            Doodle(symbol: symbol.name, fill: symbol.fills ? fill : nil, size: size * 0.8)
        } else {
            Text(emoji).font(.system(size: size * 0.85))
        }
    }
}

#if DEBUG
/// Every habit doodle. Launch with `-iconGallery` to see it.
struct DoodleGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: "HABITUDES")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(HabitDoodle.habitIcons, id: \.self) { emoji in
                        VStack(spacing: 6) {
                            EmojiIcon(emoji: emoji, size: 40)
                                .frame(width: 64, height: 64)
                                .sketchCard(fill: Theme.pink, radius: 14)
                            Text(emoji).font(.caption)
                        }
                    }
                }
                HStack(spacing: 20) {
                    Doodle(symbol: "flame", fill: Theme.coral, size: 28)
                    Doodle(symbol: "heart", fill: Theme.pink, size: 28)
                    Doodle(symbol: "bolt", fill: Theme.yellow, size: 28)
                    BoneDoodle(size: 28)
                    Doodle(symbol: "tree", fill: Theme.mint, size: 28)
                    Doodle(symbol: "lock", fill: Theme.card, size: 28)
                }
            }
            .padding(24)
            .padding(.top, 40)
        }
        .background(DottedPaper())
    }
}
#endif
