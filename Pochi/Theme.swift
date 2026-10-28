import SwiftUI

/// Sketchbook look: cream dotted paper, chunky ink outlines with hard offset shadows,
/// pastel accents, heavy titles and handwritten notes.
enum Theme {
    static let paper = Color(hex: 0xF8F3E8)
    static let dot = Color(hex: 0xDDD3BE)
    static let card = Color(hex: 0xFFFCF5)
    static let ink = Color(hex: 0x1D1916)

    static let yellow = Color(hex: 0xF7D35C)
    static let coral = Color(hex: 0xEE7356)
    static let mint = Color(hex: 0x8FDDB0)
    static let periwinkle = Color(hex: 0x8E9BE6)
    static let pink = Color(hex: 0xEC9AB5)

    static let accent = coral
    static let heat = LinearGradient(
        colors: [Color(hex: 0xC2456A), accent],
        startPoint: .leading, endPoint: .trailing
    )

    static let outline: CGFloat = 2.5
    /// Hard shadow offset under cards and buttons.
    static let lift = CGSize(width: 3, height: 4)

    static func mono(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
    static func title(_ size: CGFloat = 40) -> Font { .system(size: size, weight: .heavy) }
    static func hand(_ size: CGFloat = 20) -> Font { .custom("Noteworthy-Bold", size: size) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Cream paper with a faint dot grid, edge to edge.
struct DottedPaper: View {
    var spacing: CGFloat = 18

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.paper))
            var dots = Path()
            for x in stride(from: spacing / 2, through: size.width, by: spacing) {
                for y in stride(from: spacing / 2, through: size.height, by: spacing) {
                    dots.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                }
            }
            ctx.fill(dots, with: .color(Theme.dot))
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// A sketchbook card behind the view: ink outline and a hard shadow down-right.
    func sketchCard(fill: Color = Theme.card, shadow: Color = Theme.ink, radius: CGFloat = 18) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(shadow)
                    .offset(Theme.lift)
                // Opaque base so a translucent fill doesn't let the shadow through.
                RoundedRectangle(cornerRadius: radius).fill(Theme.card)
                RoundedRectangle(cornerRadius: radius).fill(fill)
                RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.ink, lineWidth: Theme.outline)
            }
        }
    }

    /// A small handwritten aside, slightly tilted, like a note in a margin.
    func handNote(_ color: Color = Theme.coral, size: CGFloat = 20, tilt: Double = -3) -> some View {
        font(Theme.hand(size))
            .foregroundStyle(color)
            .rotationEffect(.degrees(tilt), anchor: .leading)
    }
}
