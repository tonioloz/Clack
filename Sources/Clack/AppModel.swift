import AppKit
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            handleEnabledChange()
        }
    }

    @Published var selectedKey: KeyNote {
        didSet {
            UserDefaults.standard.set(selectedKey.rawValue, forKey: Keys.selectedKey)
            updateNoteMapper()
        }
    }

    @Published var selectedScale: ScaleType {
        didSet {
            UserDefaults.standard.set(selectedScale.rawValue, forKey: Keys.selectedScale)
            updateNoteMapper()
        }
    }

    @Published var selectedSound: SoundProfileType {
        didSet {
            UserDefaults.standard.set(selectedSound.rawValue, forKey: Keys.selectedSound)
            applySoundProfile(resetMixes: true)
        }
    }

    @Published var delayMix: Double {
        didSet {
            UserDefaults.standard.set(delayMix, forKey: Keys.delayMix)
            audioEngine.setDelayMix(delayMix)
        }
    }

    @Published var filterMix: Double {
        didSet {
            UserDefaults.standard.set(filterMix, forKey: Keys.filterMix)
            audioEngine.setFilterMix(filterMix)
        }
    }

    @Published private(set) var captureStatus: String = "Idle"
    @Published private(set) var captureDetail: String = ""
    @Published private(set) var captureMode: String = "None"
    @Published private(set) var accessibilityStatus: String = "Unknown"
    @Published private(set) var inputMonitoringStatus: String = "Unknown"
    @Published private(set) var lastKeyInfo: String = "No keys yet"
    @Published private(set) var bundleId: String = "Unknown"
    @Published private(set) var bundlePath: String = "Unknown"

    private let audioEngine = ClackAudioEngine()
    private let keyCapture = KeyCaptureManager()
    private var noteMapper: NoteMapper
    private var wordTracker = WordTracker()
    private var lastKeyTime: TimeInterval?

    init() {
        let defaults = UserDefaults.standard

        let keyRaw = defaults.string(forKey: Keys.selectedKey) ?? KeyNote.a.rawValue
        let scaleRaw = defaults.string(forKey: Keys.selectedScale) ?? ScaleType.minorPentatonic.rawValue
        let soundRaw = defaults.string(forKey: Keys.selectedSound) ?? SoundProfileType.spaceyRhodes.rawValue

        let initialKey = KeyNote(rawValue: keyRaw) ?? .a
        let initialScale = ScaleType(rawValue: scaleRaw) ?? .minorPentatonic
        let initialSound = SoundProfileType(rawValue: soundRaw) ?? .spaceyRhodes

        let initialDelay = defaults.object(forKey: Keys.delayMix) as? Double ?? initialSound.profile.defaultDelayMix
        let initialFilter = defaults.object(forKey: Keys.filterMix) as? Double ?? initialSound.profile.defaultFilterMix
        let initialEnabled = defaults.bool(forKey: Keys.isEnabled)

        _selectedKey = Published(initialValue: initialKey)
        _selectedScale = Published(initialValue: initialScale)
        _selectedSound = Published(initialValue: initialSound)
        _delayMix = Published(initialValue: initialDelay)
        _filterMix = Published(initialValue: initialFilter)
        _isEnabled = Published(initialValue: initialEnabled)

        noteMapper = NoteMapper(key: initialKey, scale: initialScale)

        bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        bundlePath = Bundle.main.bundlePath

        audioEngine.setDelayMix(initialDelay)
        audioEngine.setFilterMix(initialFilter)
        audioEngine.setReverbMix(initialSound.profile.defaultReverbMix)
        audioEngine.apply(profile: initialSound.profile)

        keyCapture.onKeyDown = { [weak self] keyEvent in
            self?.handleKeyEvent(keyEvent)
        }

        refreshPermissionStatus()
        handleEnabledChange()
    }

    private func handleEnabledChange() {
        refreshPermissionStatus()
        if isEnabled {
            let accessAllowed = accessibilityStatus == "Allowed"
            let inputAllowed = inputMonitoringStatus == "Allowed"
            guard accessAllowed && inputAllowed else {
                captureStatus = "Permission required"
                captureMode = "None"
                if !accessAllowed && !inputAllowed {
                    captureDetail = "Accessibility + Input Monitoring required"
                } else if !accessAllowed {
                    captureDetail = "Accessibility required"
                } else {
                    captureDetail = "Input Monitoring required"
                }
                isEnabled = false
                return
            }

            switch keyCapture.start() {
            case .success:
                captureStatus = "Capturing"
                captureMode = "Event Tap"
                captureDetail = ""
            case .failure(let error):
                captureStatus = "Permission required"
                captureMode = "None"
                captureDetail = error.description
                isEnabled = false
            }
        } else {
            keyCapture.stop()
            captureStatus = accessibilityStatus == "Allowed" ? "Stopped" : "Permission required"
            captureDetail = ""
            captureMode = "None"
        }
    }

    private func updateNoteMapper() {
        noteMapper = NoteMapper(key: selectedKey, scale: selectedScale)
    }

    private func applySoundProfile(resetMixes: Bool) {
        audioEngine.apply(profile: selectedSound.profile)
        if resetMixes {
            delayMix = selectedSound.profile.defaultDelayMix
            filterMix = selectedSound.profile.defaultFilterMix
            audioEngine.setDelayMix(delayMix)
            audioEngine.setFilterMix(filterMix)
            audioEngine.setReverbMix(selectedSound.profile.defaultReverbMix)
        }
    }

    private func handleKeyEvent(_ event: KeyEvent) {
        guard isEnabled else { return }
        guard !isSecureInputActive() else { return }

        let now = event.timestamp
        let velocity = velocityFromTiming(now)
        lastKeyInfo = event.character.map { "Last: \($0)" } ?? "Last: keyCode \(event.keyCode)"

        if event.isBackspace {
            wordTracker.backspace()
            playBoundaryNote(velocity: velocity, seed: "__backspace__")
            return
        }

        if let char = event.character {
            if wordTracker.isWordCharacter(char) {
                let (word, position) = wordTracker.append(char)
                let note = noteMapper.note(for: word, position: position)
                audioEngine.play(note: note, velocity: velocity)
            } else {
                wordTracker.reset()
                playBoundaryNote(velocity: velocity, seed: "__boundary__")
            }
        } else {
            playBoundaryNote(velocity: velocity, seed: "__nonchar__")
        }
    }

    private func playBoundaryNote(velocity: UInt8, seed: String) {
        let note = noteMapper.note(for: seed, position: 0)
        audioEngine.play(note: note, velocity: velocity)
    }

    private func velocityFromTiming(_ now: TimeInterval) -> UInt8 {
        let minVelocity: Double = 40
        let maxVelocity: Double = 127
        let minDelta: Double = 0.05
        let maxDelta: Double = 0.30

        defer { lastKeyTime = now }

        guard let last = lastKeyTime else {
            return UInt8((minVelocity + maxVelocity) / 2)
        }

        let delta = max(minDelta, min(maxDelta, now - last))
        let t = 1 - ((delta - minDelta) / (maxDelta - minDelta))
        let velocity = minVelocity + t * (maxVelocity - minVelocity)
        return UInt8(velocity.rounded())
    }

    private func isSecureInputActive() -> Bool {
        return SecureInputChecker.isSecureInputEnabled()
    }

    func refreshPermissionStatus() {
        accessibilityStatus = SecureInputChecker.isAccessibilityTrusted() ? "Allowed" : "Not Allowed"
        inputMonitoringStatus = SecureInputChecker.isInputMonitoringAllowed() ? "Allowed" : "Not Allowed"
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: Bundle.main.bundlePath)])
    }

    func playTestNote() {
        let note = noteMapper.note(for: "__test__", position: 0)
        audioEngine.play(note: note, velocity: 100)
    }

    func toggleEnabled() {
        isEnabled.toggle()
    }
}

private enum Keys {
    static let isEnabled = "clack.isEnabled"
    static let selectedKey = "clack.selectedKey"
    static let selectedScale = "clack.selectedScale"
    static let selectedSound = "clack.selectedSound"
    static let delayMix = "clack.delayMix"
    static let filterMix = "clack.filterMix"
}
