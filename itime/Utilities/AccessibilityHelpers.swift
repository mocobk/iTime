import AppKit

/// Accessibility helper functions for VoiceOver support.
enum AccessibilityHelpers {

    /// Announce a message to VoiceOver.
    static func announceToVoiceOver(_ message: String) {
        guard let app = NSApp else { return }
        NSAccessibility.post(
            element: app,
            notification: .announcementRequested,
            userInfo: [.announcement: message]
        )
    }

    /// Check if the process is trusted for accessibility.
    static func isProcessTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permission with prompt.
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
