import CoreHaptics
import UIKit

/// Duolingo-style feedback for each moment: a short, punchy vibration pattern that gets
/// bigger as you achieve more, plus its 8-bit sound (see Sound). Vibrations fall back to the
/// standard feedback generators where Core Haptics isn't available.
@MainActor
enum Feedback {
    private static let engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = try? CHHapticEngine() else { return nil }
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak engine] in try? engine?.start() }
        return engine
    }()

    /// Finger down on a card: a small dry tick.
    static func press() {
        play([tap(0, 0.45, 0.9)]) { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5) }
    }

    /// Habit checked: a "ba-DUM" that gets stronger with each habit done today.
    static func check(combo: Int) {
        Sound.check(combo: combo)
        let boost = Float(min(combo, 5)) * 0.06
        play([tap(0, 0.55 + boost, 0.4), tap(0.07, min(0.85 + boost, 1), 0.9)]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Habit unchecked: one soft, dull tap.
    static func uncheck() {
        Sound.uncheck()
        play([tap(0, 0.35, 0.15)]) { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5) }
    }

    /// Everything done: four rising taps, then a short rumble.
    static func perfectDay() {
        Sound.perfectDay()
        let rising = (0..<4).map { i in tap(Double(i) * 0.08, 0.5 + Float(i) * 0.17, 0.5 + Float(i) * 0.15) }
        play(rising + [buzz(0.34, 0.35, 0.8, 0.3)]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// New level: taps that speed up and grow, then a big final hit.
    static func levelUp() {
        Sound.levelUp()
        let times = [0, 0.16, 0.29, 0.39, 0.46, 0.51]
        let drumroll = times.enumerated().map { i, t in tap(t, 0.3 + Float(i) * 0.1, 0.5) }
        play(drumroll + [tap(0.62, 1, 1), buzz(0.62, 0.45, 0.9, 0.2)]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Petting Pochi: a little purr.
    static func pet() {
        Sound.pet()
        let purr = (0..<6).map { i in tap(Double(i) * 0.05, 0.35, 0.1) }
        play(purr) { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    }

    /// New habit saved: a short "ta-da".
    static func added() {
        Sound.added()
        play([tap(0, 0.6, 0.6), tap(0.1, 0.9, 0.9)]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Building blocks

    private static func tap(_ time: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }

    private static func buzz(_ time: TimeInterval, _ duration: TimeInterval,
                             _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time, duration: duration)
    }

    private static func play(_ events: [CHHapticEvent], fallback: () -> Void) {
        guard let engine else { return fallback() }
        do {
            try engine.start()
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }
}
