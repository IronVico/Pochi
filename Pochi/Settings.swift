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
    @State private var height: CGFloat = 250

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

            HealthSection()
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .presentationBackground { DottedPaper() }
    }
}

/// Connect Apple Health, and show what it reads today so we know the link works.
private struct HealthSection: View {
    private let health = Health.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SANTÉ")
                .font(Theme.mono(12))
                .tracking(2)
                .foregroundStyle(Theme.coral)

            if !health.isAvailable {
                Text("Apple Santé n'est pas disponible sur cet appareil.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.7))
            } else if health.isConnected {
                VStack(spacing: 0) {
                    HealthRow(symbol: "figure.walk", label: "Pas", value: health.today.map { "\($0.steps.formatted())" })
                    HealthRow(symbol: "bed.double.fill", label: "Sommeil", value: health.today.map { Self.hours($0.sleepHours) })
                    HealthRow(symbol: "flame.fill", label: "Exercice", value: health.today.map { "\($0.exerciseMinutes) min" })
                    HealthRow(symbol: "figure.run", label: "Séances", value: health.today.map { "\($0.workouts)" })
                    HealthRow(symbol: "leaf.fill", label: "Pleine conscience", value: health.today.map { "\($0.mindfulMinutes) min" }, last: true)
                }
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.line, lineWidth: Theme.outline) }

                Button("Déconnecter") { health.disconnect() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            } else {
                Button {
                    Task { await health.connect() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Theme.coral)
                        Text("Connecter Apple Santé")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.darkInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.yellow))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.line, lineWidth: Theme.outline) }
                }
                .buttonStyle(PressableStyle(radius: 16))
                Text("Lecture seule : Pochi ne modifie jamais tes données.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
        }
        .task { await health.refresh() }
    }

    private static func hours(_ value: Double) -> String {
        let minutes = Int((value * 60).rounded())
        return "\(minutes / 60) h \(String(format: "%02d", minutes % 60))"
    }
}

private struct HealthRow: View {
    let symbol: String
    let label: String
    let value: String?
    var last = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.coral)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text(value ?? "…")
                .font(Theme.mono(15))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(Theme.line.opacity(0.15)).frame(height: 1).padding(.horizontal, 14) }
        }
    }
}
