@preconcurrency import AppKit
@preconcurrency import ApplicationServices

struct KeyEvent {
    let keyCode: CGKeyCode
    let character: Character?
    let timestamp: TimeInterval

    var isBackspace: Bool { keyCode == 51 }
}

final class KeyCaptureManager: @unchecked Sendable {
    var onKeyDown: ((KeyEvent) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private let queue = DispatchQueue(label: "clack.eventtap")
    private(set) var isRunning: Bool = false

    enum StartError: Error, CustomStringConvertible {
        case tapCreateFailed

        var description: String {
            switch self {
            case .tapCreateFailed:
                return "Event tap creation failed"
            }
        }
    }

    func start() -> Result<Void, StartError> {
        if eventTap != nil {
            isRunning = true
            return .success(())
        }

        let mask = (1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard type == .keyDown, let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<KeyCaptureManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handle(event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) ?? CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard type == .keyDown, let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<KeyCaptureManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handle(event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return .failure(.tapCreateFailed)
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        queue.async { [weak self] in
            guard let self else { return }
            let runLoop = CFRunLoopGetCurrent()
            self.runLoop = runLoop
            if let source = self.runLoopSource {
                CFRunLoopAddSource(runLoop, source, .commonModes)
                CGEvent.tapEnable(tap: eventTap, enable: true)
                self.isRunning = true
                CFRunLoopRun()
            }
        }

        return .success(())
    }

    func stop() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        if let runLoop, let source = runLoopSource {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
            CFRunLoopStop(runLoop)
        }
        runLoopSource = nil
        self.eventTap = nil
        runLoop = nil
        isRunning = false
    }

    private func handle(event: CGEvent) {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let character = event.character
        let timestamp = TimeInterval(event.timestamp) / 1_000_000_000
        let keyEvent = KeyEvent(keyCode: keyCode, character: character, timestamp: timestamp)

        DispatchQueue.main.async { [weak self] in
            self?.onKeyDown?(keyEvent)
        }
    }
}

private extension CGEvent {
    var character: Character? {
        var length: Int = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &buffer)
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: buffer, count: length).first
    }
}
