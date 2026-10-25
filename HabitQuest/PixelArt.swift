import SwiftUI
import UIKit

// MARK: - Sprites

/// Draws a character grid as square pixels. `.` is transparent; other characters
/// come from `PixelIcon.palette`, or all take `tint` when one is given.
struct PixelSprite: View {
    let grid: [String]
    var pixel: CGFloat = 2
    var tint: Color?

    var body: some View {
        let rows = grid.map(Array.init)
        Canvas { ctx, _ in
            for (r, line) in rows.enumerated() {
                for (c, ch) in line.enumerated() {
                    guard let color = ch == "." ? nil : (tint ?? PixelIcon.palette[ch]) else { continue }
                    ctx.fill(Path(CGRect(x: CGFloat(c) * pixel, y: CGFloat(r) * pixel,
                                         width: pixel + 0.1, height: pixel + 0.1)),
                             with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(rows.first?.count ?? 0) * pixel, height: CGFloat(rows.count) * pixel)
    }
}

/// 12 × 12 pixel icons.
enum PixelIcon {
    static let palette: [Character: Color] = [
        "O": Color(red: 0.91, green: 0.57, blue: 0.23), // orange
        "Y": Color(red: 1.00, green: 0.82, blue: 0.36), // yellow
        "N": Color(red: 0.36, green: 0.82, blue: 0.48), // green
        "P": Color(red: 0.96, green: 0.64, blue: 0.64), // pink
        "G": Color(white: 0.48), // dark grey
        "L": Color(white: 0.68), // light grey
        "K": Color(white: 0.10), // black
    ]

    static let check = [
        "............",
        "..........NN",
        ".........NNN",
        "........NNN.",
        ".......NNN..",
        ".NN...NNN...",
        ".NNN.NNN....",
        "..NNNNNN....",
        "...NNNN.....",
        "....NN......",
        "............",
        "............",
    ]

    static let flame = [
        "....O.......",
        "....OO......",
        "...OOO......",
        "...OOOO..O..",
        "..OOOOO.OO..",
        "..OOOOOOOO..",
        ".OOOOYOOOOO.",
        ".OOOYYYOOOO.",
        ".OOYYYYYOOO.",
        ".OOYYYYYYOO.",
        "..OOYYYYOO..",
        "...OOOOOO...",
    ]

    static let bolt = [
        "......YYYY..",
        ".....YYYY...",
        "....YYYY....",
        "...YYYY.....",
        "..YYYYYYYY..",
        ".YYYYYYYY...",
        ".....YYYY...",
        "....YYYY....",
        "...YYY......",
        "..YYY.......",
        "..YY........",
        ".Y..........",
    ]

    static let star = [
        ".....YY.....",
        ".....YY.....",
        "....YYYY....",
        "YYYYYYYYYYYY",
        ".YYYYYYYYYY.",
        "..YYYYYYYY..",
        "...YYYYYY...",
        "..YYYYYYYY..",
        "..YYY..YYY..",
        ".YYY....YYY.",
        ".YY......YY.",
        "............",
    ]

    static let sparkle = [
        "....P.......",
        "....P.......",
        "...PPP......",
        ".PPPPPPP....",
        "...PPP......",
        "....P.......",
        "....P....P..",
        ".........P..",
        "........PPP.",
        "......PPPPPP",
        "........PPP.",
        ".........P..",
    ]

    static let trophy = [
        ".YYYYYYYYYY.",
        "YY.YYYYYY.YY",
        "Y..YYYYYY..Y",
        "Y..YYYYYY..Y",
        ".Y.YYYYYY.Y.",
        "..YYYYYYYY..",
        "....YYYY....",
        ".....YY.....",
        ".....YY.....",
        "....YYYY....",
        "...YYYYYY...",
        "...YYYYYY...",
    ]

    static let chart = [
        "............",
        ".........YY.",
        ".........YY.",
        "......YY.YY.",
        "......YY.YY.",
        "......YY.YY.",
        "...YY.YY.YY.",
        "...YY.YY.YY.",
        "YY.YY.YY.YY.",
        "YY.YY.YY.YY.",
        "YYYYYYYYYYY.",
        "............",
    ]

    static let lock = [
        "............",
        "...GGGGGG...",
        "..GG....GG..",
        "..G......G..",
        "..G......G..",
        ".LLLLLLLLLL.",
        ".LLLLKKLLLL.",
        ".LLLLKKLLLL.",
        ".LLLLLKLLLL.",
        ".LLLLLKLLLL.",
        ".LLLLLLLLLL.",
        "............",
    ]

    /// A one-colour template image, for places that need an `Image` (the tab bar).
    static func templateImage(_ grid: [String], pixel: CGFloat = 2) -> Image {
        let rows = grid.map(Array.init)
        let size = CGSize(width: CGFloat(rows[0].count) * pixel, height: CGFloat(rows.count) * pixel)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.black.setFill()
            for (r, line) in rows.enumerated() {
                for (c, ch) in line.enumerated() where ch != "." {
                    ctx.fill(CGRect(x: CGFloat(c) * pixel, y: CGFloat(r) * pixel, width: pixel, height: pixel))
                }
            }
        }
        return Image(uiImage: image.withRenderingMode(.alwaysTemplate))
    }
}

// MARK: - Panels

/// A rectangle with stepped pixel corners, optionally with a stepped tail on the left
/// (for speech bubbles).
struct PixelFrame: Shape {
    var unit: CGFloat = 3
    var tail = false

    static func tailWidth(unit: CGFloat = 3) -> CGFloat { unit * 3 }

    func path(in rect: CGRect) -> Path {
        let u = unit
        let l = rect.minX + (tail ? Self.tailWidth(unit: u) : 0), r = rect.maxX, t = rect.minY, b = rect.maxY
        let cy = (rect.minY + rect.maxY) / 2
        var points = [
            CGPoint(x: l + 2 * u, y: t),
            // Top-right corner
            CGPoint(x: r - 2 * u, y: t), CGPoint(x: r - 2 * u, y: t + u), CGPoint(x: r - u, y: t + u),
            CGPoint(x: r - u, y: t + 2 * u), CGPoint(x: r, y: t + 2 * u),
            // Bottom-right corner
            CGPoint(x: r, y: b - 2 * u), CGPoint(x: r - u, y: b - 2 * u), CGPoint(x: r - u, y: b - u),
            CGPoint(x: r - 2 * u, y: b - u), CGPoint(x: r - 2 * u, y: b),
            // Bottom-left corner
            CGPoint(x: l + 2 * u, y: b), CGPoint(x: l + 2 * u, y: b - u), CGPoint(x: l + u, y: b - u),
            CGPoint(x: l + u, y: b - 2 * u), CGPoint(x: l, y: b - 2 * u),
        ]
        if tail {
            points += [
                CGPoint(x: l, y: cy + 2 * u), CGPoint(x: l - 3 * u, y: cy + 2 * u), CGPoint(x: l - 3 * u, y: cy + u),
                CGPoint(x: l - 2 * u, y: cy + u), CGPoint(x: l - 2 * u, y: cy), CGPoint(x: l - u, y: cy),
                CGPoint(x: l - u, y: cy - u), CGPoint(x: l, y: cy - u),
            ]
        }
        points += [
            // Top-left corner
            CGPoint(x: l, y: t + 2 * u), CGPoint(x: l + u, y: t + 2 * u), CGPoint(x: l + u, y: t + u),
            CGPoint(x: l + 2 * u, y: t + u),
        ]
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }
}

extension View {
    /// A pixel panel behind the view: a stepped frame with a 1-unit border.
    func pixelPanel(fill: Color = Color(white: 0.11), border: Color = Color(white: 0.2), unit: CGFloat = 3) -> some View {
        background {
            ZStack {
                PixelFrame(unit: unit).fill(border)
                PixelFrame(unit: unit).fill(fill).padding(unit)
            }
        }
    }
}

/// A progress bar made of separate blocks.
struct PixelBlocksBar: View {
    let filled: Int
    let total: Int
    var color: Color = Theme.accent

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? color : Color(white: 0.16))
                    .frame(height: 14)
            }
        }
        .animation(.snappy, value: filled)
    }
}

/// Duolingo-style 3D pixel button: a darker lip under the face, which sinks onto it while pressed.
struct PixelButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var lip = Color(red: 0.62, green: 0.25, blue: 0.16)
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .tracking(2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(PixelFrame().fill(color))
            .offset(y: configuration.isPressed ? depth : 0)
            .background(PixelFrame().fill(lip).offset(y: depth))
            .padding(.bottom, depth)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.press() }
            }
    }
}

/// Small monospaced section title, as on the home screen.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.mono(20))
            .tracking(2)
            .foregroundStyle(.secondary)
    }
}
