import Foundation

/// Detects Unix timestamps from string input and determines precision.
enum TimestampDetector {

    /// Attempt to detect a Unix timestamp in the input string.
    /// Returns the resolved Date and its unit, or nil if not a timestamp.
    static func detect(_ input: String) -> (Date, TimestampUnit)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Must be numeric (optional leading minus, optional decimal point)
        let pattern = "^-?\\d+(\\.\\d+)?$"
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }

        // Handle decimal timestamps (e.g., "1704067200.5")
        if trimmed.contains(".") {
            let parts = trimmed.split(separator: ".", maxSplits: 1)
            guard let intPart = Int64(parts[0]) else { return nil }
            let date = Date(timeIntervalSince1970: TimeInterval(intPart))
            guard isValidDate(date) else { return nil }
            return (date, .seconds)
        }

        // Pure integer
        guard let value = Int64(trimmed) else { return nil }

        // Determine precision by digit count
        let absValue = abs(value)
        let digitCount = String(absValue).count

        let unit: TimestampUnit
        let seconds: TimeInterval

        switch digitCount {
        case 1...10:
            unit = .seconds
            seconds = TimeInterval(value)
        case 11...13:
            unit = .milliseconds
            seconds = TimeInterval(value) / 1_000.0
        case 14...16:
            unit = .microseconds
            seconds = TimeInterval(value) / 1_000_000.0
        default:
            return nil
        }

        let date = Date(timeIntervalSince1970: seconds)
        guard isValidDate(date) else { return nil }
        return (date, unit)
    }

    /// Validate that the date falls within a reasonable range.
    /// Accepts dates from 0001-01-01 to 2286-11-20 (edge of 11-digit seconds).
    private static func isValidDate(_ date: Date) -> Bool {
        // 2286-11-20 17:46:40 UTC = 9999999999 seconds (10-digit max)
        // But we extend to 11-digit seconds max: 99999999999 = ~5138 year
        // Use a reasonable upper bound: year 9999
        let maxTimestamp: TimeInterval = 253402300799 // 9999-12-31 23:59:59 UTC
        let minTimestamp: TimeInterval = -62135596800  // 0001-01-01 00:00:00 UTC

        let interval = date.timeIntervalSince1970
        return interval >= minTimestamp && interval <= maxTimestamp
    }
}
