import Carbon
import AppKit

@MainActor
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyId: UInt32 = 1

    private init() {}

    func registerToggleHotKey() {
        unregisterHotKey()

        let modifierFlags: UInt32 = UInt32(optionKey | cmdKey)
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4143), id: hotKeyId) // 'CLAC'

        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            modifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, _ in
            guard let eventRef else { return noErr }
            var capturedID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &capturedID
            )
            if status == noErr && capturedID.id == HotKeyManager.shared.hotKeyId {
                NotificationCenter.default.post(name: .clackToggleHotKey, object: nil)
            }
            return noErr
        }, 1, &eventType, nil, &eventHandlerRef)
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}

extension Notification.Name {
    static let clackToggleHotKey = Notification.Name("clack.toggle.hotkey")
}
