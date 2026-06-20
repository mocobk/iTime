import AppKit

/// Manages clipboard read/write operations.
@MainActor
final class ClipboardService {
    static let shared = ClipboardService()

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
    }

    // MARK: - Private

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
