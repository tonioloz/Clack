import Carbon
@preconcurrency import ApplicationServices

enum SecureInputChecker {
    static func isSecureInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }

    static func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }

    static func isInputMonitoringAllowed() -> Bool {
        return CGPreflightListenEventAccess()
    }

    static func requestInputMonitoringAccess() {
        CGRequestListenEventAccess()
    }
}
