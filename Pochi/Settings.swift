import SwiftUI

/// Light or dark: follow the phone, or force one.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let key = "appearance"

    var id: String { rawValue }

    /// Set on the windows rather than with `preferredColorScheme`, which doesn't
    /// hand control back to the system to an open sheet when it goes back to `nil`.
    func apply() {
        let style: UIUserInterfaceStyle = switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows { window.overrideUserInterfaceStyle = style }
        }
    }

    var label: String {
        switch self {
        case .system: "Auto"
        case .light: "Clair"
        case .dark: "Sombre"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}

/// The settings sheet, opened from the gear on the home screen.
struct SettingsSheet: View {
    @AppStorage(Appearance.key) private var appearance = Appearance.system
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Réglages")
                    .font(Theme.title(30))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .heavy))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.card))
                        .overlay { Circle().strokeBorder(Theme.line, lineWidth: Theme.outline) }
                }
                .buttonStyle(PressableStyle(radius: 18))
                .accessibilityLabel("Fermer")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("APPARENCE")
                    .font(Theme.mono(12))
                    .tracking(2)
                    .foregroundStyle(Theme.coral)
                HStack(spacing: 10) {
                    ForEach(Appearance.allCases) { option in
                        let selected = option == appearance
                        Button {
                            withAnimation(.snappy) { appearance = option }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: option.symbol)
                                    .font(.system(size: 22, weight: .bold))
                                Text(option.label)
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(selected ? Theme.darkInk : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(selected ? Theme.yellow : Theme.card))
                            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.line, lineWidth: Theme.outline) }
                        }
                        .buttonStyle(PressableStyle(radius: 16))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
        .presentationBackground { DottedPaper() }
    }
}
