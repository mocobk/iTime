import Foundation

/// Output precision for timestamp conversion.
enum OutputPrecision: String, CaseIterable, Sendable, Codable {
    case seconds = "seconds"
    case milliseconds = "milliseconds"

    var multiplier: Double {
        switch self {
        case .seconds: return 1
        case .milliseconds: return 1_000
        }
    }

    var displayName: String {
        switch self {
        case .seconds: return "秒"
        case .milliseconds: return "毫秒"
        }
    }
}

/// Formats conversion output strings.
enum OutputFormatter {

    /// Format a Date as a human-readable date string.
    /// Output: "yyyy-MM-dd HH:mm:ss" in local timezone.
    static func formatDate(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Format a Date as a Unix timestamp string.
    static func formatTimestamp(from date: Date, precision: OutputPrecision = .seconds) -> String {
        let interval = date.timeIntervalSince1970
        let value = interval * precision.multiplier
        // Use Int64 for clean integer output
        let intValue = Int64(value.rounded())
        return String(intValue)
    }

    /// Format a toast message: "input → output"
    static func formatToastMessage(input: String, output: String) -> String {
        "\(input) → \(output)"
    }

    // MARK: - Cached Formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = DateFormatStrings.displayDate
        f.locale = Locale.current
        return f
    }()
}
