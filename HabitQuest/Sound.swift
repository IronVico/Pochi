import AVFoundation

/// 8-bit sound effects, synthesised in code (square waves), so there are no audio files.
/// Plays in the "ambient" category: silent when the iPhone is on mute, mixes with music.
@MainActor
enum Sound {
    private struct Note {
        let from: Double // Hz
        let to: Double // Hz, for little pitch slides
        let start: Double // seconds
        let length: Double // seconds
    }

    private static let sampleRate = 44_100.0
    private static let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private static let engine = AVAudioEngine()
    /// A few players so overlapping sounds don't cut each other off.
    private static let players = (0..<4).map { _ in AVAudioPlayerNode() }
    private static var nextPlayer = 0
    private static var isSetUp = false

    /// Habit checked: two rising notes, higher with each habit done today.
    static func check(combo: Int) {
        let base = 72 + min(max(combo - 1, 0), 5) * 2
        play([note(base, at: 0, for: 0.07), note(base + 7, at: 0.06, for: 0.11)])
    }

    /// Habit unchecked: a soft falling "boop".
    static func uncheck() {
        play([note(64, at: 0, for: 0.07), note(57, at: 0.06, for: 0.1)], volume: 0.1)
    }

    /// Everything done: a quick arpeggio.
    static func perfectDay() {
        play([note(72, at: 0, for: 0.08), note(76, at: 0.08, for: 0.08),
              note(79, at: 0.16, for: 0.08), note(84, at: 0.24, for: 0.3)])
    }

    /// New level: a little fanfare.
    static func levelUp() {
        play([note(67, at: 0, for: 0.09), note(72, at: 0.1, for: 0.09), note(76, at: 0.2, for: 0.09),
              note(79, at: 0.3, for: 0.12), note(84, at: 0.45, for: 0.45), note(88, at: 0.45, for: 0.45)])
    }

    /// Petting Pochi: two little "yips".
    static func pet() {
        play([Note(from: 950, to: 600, start: 0, length: 0.06),
              Note(from: 1050, to: 650, start: 0.11, length: 0.07)])
    }

    /// New habit: "ta-da".
    static func added() {
        play([note(72, at: 0, for: 0.07), note(79, at: 0.08, for: 0.16)])
    }

    // MARK: - Synthesis

    private static func note(_ midi: Int, at start: Double, for length: Double) -> Note {
        let hz = 440 * pow(2, Double(midi - 69) / 12)
        return Note(from: hz, to: hz, start: start, length: length)
    }

    private static func play(_ notes: [Note], volume: Float = 0.16) {
        guard setUp(), let buffer = render(notes, volume: volume) else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private static func setUp() -> Bool {
        if !isSetUp {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            for player in players {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
            }
            isSetUp = true
        }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        return engine.isRunning
    }

    /// Square waves with a short attack and a decaying tail, mixed into one buffer.
    private static func render(_ notes: [Note], volume: Float) -> AVAudioPCMBuffer? {
        let duration = (notes.map { $0.start + $0.length }.max() ?? 0) + 0.02
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) { samples[i] = 0 }

        for note in notes {
            let first = Int(note.start * sampleRate)
            let count = Int(note.length * sampleRate)
            var phase = 0.0
            for i in 0..<count where first + i < Int(frames) {
                let t = Double(i) / Double(count)
                let hz = note.from + (note.to - note.from) * t
                phase += hz / sampleRate
                let square: Float = phase.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : -1
                let attack = min(Double(i) / (0.004 * sampleRate), 1)
                let envelope = Float(attack * pow(1 - t, 1.6))
                samples[first + i] += square * envelope * volume
            }
        }
        return buffer
    }
}
