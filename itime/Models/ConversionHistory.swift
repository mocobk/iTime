import Foundation
import Observation

/// In-memory conversion history, capped at 20 entries.
/// Shared singleton so both UI and background services (HotkeyService, ServicesMenuProvider)
/// can write to the same history.
@Observable
@MainActor
final class ConversionHistory {
    static let shared = ConversionHistory()

    private(set) var entries: [ConversionResult] = []

    static let maxEntries = 20

    var latest: ConversionResult? {
        entries.first
    }

    var isEmpty: Bool {
        entries.isEmpty
    }

    func add(_ result: ConversionResult) {
        // Dedup: remove any existing entry with the same input+output,
        // so the newest one (with updated createdAt) replaces it
        entries.removeAll { entry in
            entry.input == result.input && entry.output == result.output && entry.direction == result.direction
        }
        entries.insert(result, at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
    }

    func clear() {
        entries.removeAll()
    }
}
