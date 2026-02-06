@preconcurrency import ApplicationServices

enum AccessibilityPrompt {
    static func requestIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        SecureInputChecker.requestInputMonitoringAccess()
    }
}
