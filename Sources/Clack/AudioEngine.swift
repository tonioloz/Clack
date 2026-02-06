@preconcurrency import AVFoundation
import AudioToolbox

enum SoundProfileType: String, CaseIterable, Identifiable {
    case spaceyRhodes
    case tightRhodes
    case synthPad
    case handpan
    case panFlute

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spaceyRhodes: return "Spacey Rhodes"
        case .tightRhodes: return "Tight Rhodes"
        case .synthPad: return "Synth Pad"
        case .handpan: return "Handpan"
        case .panFlute: return "Pan Flute"
        }
    }

    var profile: SoundProfile {
        switch self {
        case .spaceyRhodes:
            return SoundProfile(
                program: 4,
                delayTime: 0.35,
                delayFeedback: 28,
                defaultDelayMix: 45,
                reverbPreset: .largeHall,
                defaultReverbMix: 40
            )
        case .tightRhodes:
            return SoundProfile(
                program: 4,
                delayTime: 0.18,
                delayFeedback: 16,
                defaultDelayMix: 25,
                reverbPreset: .mediumRoom,
                defaultReverbMix: 22
            )
        case .synthPad:
            return SoundProfile(
                program: 88,
                delayTime: 0.45,
                delayFeedback: 32,
                defaultDelayMix: 35,
                reverbPreset: .largeHall,
                defaultReverbMix: 45
            )
        case .handpan:
            return SoundProfile(
                program: 114,
                delayTime: 0.28,
                delayFeedback: 24,
                defaultDelayMix: 30,
                reverbPreset: .mediumHall,
                defaultReverbMix: 38
            )
        case .panFlute:
            return SoundProfile(
                program: 75,
                delayTime: 0.25,
                delayFeedback: 18,
                defaultDelayMix: 22,
                reverbPreset: .largeRoom,
                defaultReverbMix: 35
            )
        }
    }
}

struct SoundProfile {
    let program: UInt8
    let delayTime: TimeInterval
    let delayFeedback: Float
    let defaultDelayMix: Double
    let reverbPreset: AVAudioUnitReverbPreset
    let defaultReverbMix: Double
}

@MainActor
final class ClackAudioEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let delay = AVAudioUnitDelay()
    private let reverb = AVAudioUnitReverb()

    private let midiChannel: UInt8 = 0
    private var currentProfile: SoundProfile
    private var currentDelayAmount: Double

    init() {
        let profile = SoundProfileType.spaceyRhodes.profile
        currentProfile = profile
        currentDelayAmount = profile.defaultDelayMix

        engine.attach(sampler)
        engine.attach(delay)
        engine.attach(reverb)

        let mainMixer = engine.mainMixerNode
        engine.connect(sampler, to: delay, format: nil)
        engine.connect(delay, to: reverb, format: nil)
        engine.connect(reverb, to: mainMixer, format: nil)

        apply(profile: profile)
        setDelayAmount(profile.defaultDelayMix)
        setReverbMix(profile.defaultReverbMix)
        startEngine()
    }

    func apply(profile: SoundProfile) {
        currentProfile = profile
        delay.delayTime = profile.delayTime
        delay.feedback = profile.delayFeedback
        reverb.loadFactoryPreset(profile.reverbPreset)
        setDelayAmount(currentDelayAmount)
        loadInstrument(program: profile.program)
    }

    func setDelayAmount(_ amount: Double) {
        let clamped = max(0, min(100, amount))
        currentDelayAmount = clamped
        delay.wetDryMix = Float(clamped)

        let t = clamped / 100.0
        let timeScale = 0.35 + (1.65 * t)
        let feedbackScale = 0.35 + (2.2 * t)

        let time = min(1.0, max(0.08, currentProfile.delayTime * timeScale))
        let feedback = min(85, max(5, currentProfile.delayFeedback * Float(feedbackScale)))

        delay.delayTime = time
        delay.feedback = feedback
    }

    func setReverbMix(_ mix: Double) {
        reverb.wetDryMix = Float(max(0, min(100, mix)))
    }

    func play(note: UInt8, velocity: UInt8) {
        sampler.startNote(note, withVelocity: velocity, onChannel: midiChannel)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            sampler.stopNote(note, onChannel: midiChannel)
        }
    }

    private func loadInstrument(program: UInt8) {
        let soundbankPath = "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
        let url = URL(fileURLWithPath: soundbankPath)

        do {
            try sampler.loadSoundBankInstrument(
                at: url,
                program: program,
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
}
