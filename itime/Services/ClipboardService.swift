import AppKit

/// Manages clipboard read/write and optional background monitoring.
@MainActor
final class ClipboardService {
    static let shared = ClipboardService()

    /// Callback when clipboard changes and contains a recognizable time value.
    var onTimeContentDetected: ((String) -> Void)?

    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var isMonitoring = false

    // MARK: - Read/Write

    /// Read plain text from the system clipboard.
    func readText() -> String? {
        let pb = NSPasteboard.general
        guard pb.canReadObject(forClasses: [NSString.self], options: nil) else {
            return nil
        }
        // Filter out password manager content
        if isPasswordManagerContent(pb) { return nil }
        return pb.string(forType: .string)
    }

    /// Write plain text to the system clipboard.
    func writeText(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastChangeCount = pb.changeCount
    }

    // MARK: - Monitoring

    /// Start monitoring if the user has enabled clipboard monitoring.
    func startMonitoringIfNeeded() {
        let enabled = UserDefaults.standard.bool(forKey: "clipboardMonitorEnabled")
        if enabled && !isMonitoring {
            startMonitoring()
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    // MARK: - Private

    private func checkClipboard() {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // Only process plain text
        guard pb.canReadObject(forClasses: [NSString.self], options: nil) else { return }

        // Filter password manager content
        if isPasswordManagerContent(pb) { return }

        guard let text = pb.string(forType: .string), !text.isEmpty else { return }

        // Filter: only process if it looks like time content
        // (short strings that are purely numeric or date-like)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 50 else { return }

        // Only trigger if the clipboard content is purely time-related
        let classification = ConversionEngine.classify(trimmed)
        switch classification {
        case .unixTimestamp, .dateString:
            onTimeContentDetected?(trimmed)
        case .unrecognized:
            break
        }
    }

    private func isPasswordManagerContent(_ pb: NSPasteboard) -> Bool {
        let types = pb.types ?? []
        let suspiciousTypes: Set<String> = [
            "com.1password.password",
            "com.agilebits.onepassword",
            "com.lastpass.password",
            "com.bitwarden.password",
            "org.keepassxc.password",
        ]
        return types.contains { suspiciousTypes.contains($0.rawValue) }
    }
}
