import SwiftUI

/// A progress bar made of separate outlined blocks.
struct BlocksBar: View {
    let filled: Int
    let total: Int
    var color: Color = Theme.accent
    var height: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < filled ? color : Theme.ink.opacity(0.07))
                    .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.ink, lineWidth: 1.5) }
                    .frame(height: height)
            }
        }
        .animation(.snappy, value: filled)
    }
}

/// Chunky sketchbook button: ink outline over a hard shadow, which it sinks onto while pressed.
struct ChunkyButtonStyle: ButtonStyle {
    var color: Color = Theme.yellow

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16).fill(color)
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.ink, lineWidth: Theme.outline) }
            }
            .modifier(Sinks(pressed: configuration.isPressed, shadow: Theme.ink, radius: 16))
    }
}

/// The view rests on a hard shadow down-right and sinks onto it while pressed, with a tick.
struct Sinks: ViewModifier {
    let pressed: Bool
    var shadow: Color = Theme.ink
    var radius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .offset(pressed ? Theme.lift : .zero)
            .background {
                RoundedRectangle(cornerRadius: radius).fill(shadow).offset(Theme.lift)
            }
            .padding(.trailing, Theme.lift.width)
            .padding(.bottom, Theme.lift.height)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: pressed)
            .onChange(of: pressed) { _, pressed in
                if pressed { Feedback.press() }
            }
    }
}

/// Small uppercase eyebrow over a heavy title, with an optional handwritten aside.
struct SectionLabel: View {
    let text: String
    var title: String?
    var note: String?
    var color: Color = Theme.coral

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(Theme.mono(12))
                .tracking(2)
                .foregroundStyle(color)
            if let title {
                Text(title)
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.ink)
            }
            if let note {
                Text(note)
                    .handNote(Theme.periwinkle, size: 16, tilt: -2)
                    .padding(.top, 2)
            }
        }
    }
}
