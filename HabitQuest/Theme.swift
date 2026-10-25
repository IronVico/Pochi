import SwiftUI

enum Theme {
    static let accent = Color(red: 0.93, green: 0.45, blue: 0.30)
    static let heat = LinearGradient(
        colors: [Color(red: 0.62, green: 0.16, blue: 0.26), accent],
        startPoint: .leading, endPoint: .trailing
    )

    static func mono(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}
