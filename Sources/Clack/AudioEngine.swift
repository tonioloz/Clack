@preconcurrency import AVFoundation
import AudioToolbox

enum SoundProfileType: String, CaseIterable, Identifiable {
    case spaceyRhodes
    case tightRhodes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spaceyRhodes: return "Spacey Rhodes"
        case .tightRhodes: return "Tight Rhodes"
        }
    }

    var profile: SoundProfile {
        switch self {
        case .spaceyRhodes:
            return SoundProfile(
                delayTime: 0.35,
                delayFeedback: 28,
                defaultDelayMix: 45,
                defaultFilterMix: 55,
                reverbPreset: .largeHall,
                defaultReverbMix: 40
            )
        case .tightRhodes:
            return SoundProfile(
                delayTime: 0.15,
                delayFeedback: 10,
                defaultDelayMix: 18,
                defaultFilterMix: 75,
                reverbPreset: .mediumRoom,
                defaultReverbMix: 18
            )
        }
    }
}

struct SoundProfile {
    let delayTime: TimeInterval
    let delayFeedback: Float
    let defaultDelayMix: Double
    let defaultFilterMix: Double
    let reverbPreset: AVAudioUnitReverbPreset
    let defaultReverbMix: Double
}

@MainActor
final class ClackAudioEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let eq = AVAudioUnitEQ(numberOfBands: 1)
    private let delay = AVAudioUnitDelay()
    private let reverb = AVAudioUnitReverb()

    private let midiChannel: UInt8 = 0

    init() {
        engine.attach(sampler)
        engine.attach(eq)
        engine.attach(delay)
        engine.attach(reverb)

        let mainMixer = engine.mainMixerNode
        engine.connect(sampler, to: eq, format: nil)
        engine.connect(eq, to: delay, format: nil)
        engine.connect(delay, to: reverb, format: nil)
        engine.connect(reverb, to: mainMixer, format: nil)

        configureFilter()
        apply(profile: SoundProfileType.spaceyRhodes.profile)
        loadRhodesInstrument()
        startEngine()
    }

    func apply(profile: SoundProfile) {
        delay.delayTime = profile.delayTime
        delay.feedback = profile.delayFeedback
        reverb.loadFactoryPreset(profile.reverbPreset)
    }

    func setDelayMix(_ mix: Double) {
        delay.wetDryMix = Float(max(0, min(100, mix)))
    }

    func setReverbMix(_ mix: Double) {
        reverb.wetDryMix = Float(max(0, min(100, mix)))
    }

    func setFilterMix(_ mix: Double) {
        let clamped = max(0, min(100, mix))
        let minCutoff: Float = 600
        let maxCutoff: Float = 14000
        let t = Float(clamped / 100.0)
        let cutoff = minCutoff + (maxCutoff - minCutoff) * t
        if let band = eq.bands.first {
            band.frequency = cutoff
        }
    }

    func play(note: UInt8, velocity: UInt8) {
        sampler.startNote(note, withVelocity: velocity, onChannel: midiChannel)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            sampler.stopNote(note, onChannel: midiChannel)
        }
    }

    private func loadRhodesInstrument() {
        let soundbankPath = "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
        let url = URL(fileURLWithPath: soundbankPath)

        do {
            try sampler.loadSoundBankInstrument(
                at: url,
                program: 4,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } catch {
            print("ClackAudioEngine: Failed to load sound bank instrument: \(error)")
        }
    }

    private func startEngine() {
        do {
            try engine.start()
        } catch {
            print("ClackAudioEngine: Failed to start audio engine: \(error)")
        }
    }

    private func configureFilter() {
        guard let band = eq.bands.first else { return }
        band.filterType = .lowPass
        band.bypass = false
        band.bandwidth = 1.0
        band.gain = 0
        setFilterMix(60)
    }
}
