import Foundation

/// Central conversion engine. Dispatches input to the appropriate detector/parser.
enum ConversionEngine {

    /// Convert a raw input string to a ConversionResult.
    /// Tries timestamp detection first (unambiguous), then date string parsing.
    /// Automatically extracts time-related substrings from mixed content.
    /// Returns nil if the input cannot be recognized.
    static func convert(
        _ rawInput: String,
        outputPrecision: OutputPrecision = .seconds
    ) -> ConversionResult? {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        // Try the whole input first
        if let result = tryConvert(input, originalInput: input, outputPrecision: outputPrecision) {
            return result
        }

        // If the whole input doesn't match, try extracting time substrings
        let extracted = extractTimeSubstring(input)
        if let extracted, extracted != input {
            return tryConvert(extracted, originalInput: input, outputPrecision: outputPrecision)
        }

        return nil
    }

    /// Classify the input without performing conversion.
    static func classify(_ rawInput: String) -> InputClassification {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return .unrecognized }

        // Try the whole input first
        let wholeClassification = classifySingle(input)
        if wholeClassification != .unrecognized {
            return wholeClassification
        }

        // Try extracting time substrings
        let extracted = extractTimeSubstring(input)
        if let extracted {
            return classifySingle(extracted)
        }

        return .unrecognized
    }

    // MARK: - Private

    /// Try to convert a single (possibly extracted) time string.
    /// The `input` in ConversionResult is set to the extracted/filtered time string,
    /// so only time-related characters are displayed.
    private static func tryConvert(
        _ timeString: String,
        originalInput: String,
        outputPrecision: OutputPrecision
    ) -> ConversionResult? {
        // Try timestamp first (pure digits are unambiguous)
        if let (date, _) = TimestampDetector.detect(timeString) {
            let output = OutputFormatter.formatDate(from: date)
            return ConversionResult(
                input: timeString,
                output: output,
                direction: .timestampToDate,
                resolvedDate: date,
                outputPrecision: outputPrecision
            )
        }

        // Try date string parsing
        if let (date, _) = DateParser.parse(timeString) {
            let secondsOutput = OutputFormatter.formatTimestamp(from: date, precision: .seconds)
            let millisOutput = OutputFormatter.formatTimestamp(from: date, precision: .milliseconds)
            let primaryOutput: String
            let secondary: String
            switch outputPrecision {
            case .seconds:
                primaryOutput = secondsOutput
                secondary = millisOutput
            case .milliseconds:
                primaryOutput = millisOutput
                secondary = secondsOutput
            }
            return ConversionResult(
                input: timeString,
                output: primaryOutput,
                secondaryOutput: secondary,
                direction: .dateToTimestamp,
                resolvedDate: date,
                outputPrecision: outputPrecision
            )
        }

        return nil
    }

    /// Classify a single string.
    private static func classifySingle(_ input: String) -> InputClassification {
        if let (_, unit) = TimestampDetector.detect(input) {
            return .unixTimestamp(unit: unit)
        }
        if let (_, format) = DateParser.parse(input) {
            return .dateString(format: format)
        }
        return .unrecognized
    }

    /// Extract the time-related substring from a mixed input.
    /// For example: "现在是1704067200秒" → "1704067200"
    /// For example: "the timestamp is 1704067200" → "1704067200"
    /// For example: "现在是2024年6月20日" → "2024年6月20日"
    /// Strategy (ordered by specificity):
    /// 1. Strip Chinese suffixes/prefixes (most specific, low false-positive rate)
    /// 2. Find date-like patterns (for inputs with date indicator chars)
    /// 3. Extract numeric sequences (for timestamps)
    /// 4. Token-based splitting (fallback)
    static func extractTimeSubstring(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strategy 1: Strip common Chinese suffixes/prefixes
        // "1704067200秒" → "1704067200", "时间戳1704067200" → "1704067200"
        let chineseSuffixes = ["秒", "毫秒", "微秒", "前", "后", "时间戳", "时间"]
        let chinesePrefixes = ["时间戳", "时间", "当前", "现在"]

        for suffix in chineseSuffixes {
            if trimmed.hasSuffix(suffix) {
                let candidate = String(trimmed.dropLast(suffix.count))
                if TimestampDetector.detect(candidate) != nil || DateParser.parse(candidate) != nil {
                    return candidate
                }
            }
        }
        for prefix in chinesePrefixes {
            if trimmed.hasPrefix(prefix) {
                let candidate = String(trimmed.dropFirst(prefix.count))
                if TimestampDetector.detect(candidate) != nil || DateParser.parse(candidate) != nil {
                    return candidate
                }
            }
        }

        // Strategy 2: Find date-like patterns by progressively trimming non-time characters
        // "现在是2024年6月20日" → trim prefix "现在是" → "2024年6月20日"
        // "2024-01-15 at meeting" → trim suffix " at meeting" → "2024-01-15"
        let dateIndicators: Set<Character> = ["年", "月", "日", "-", "/", ".", ":", "T"]
        if input.contains(where: { dateIndicators.contains($0) }) {
            // Trim prefix characters one by one
            var str = trimmed
            while !str.isEmpty {
                if DateParser.parse(str) != nil { return str }
                str.removeFirst()
            }
            // Also try trimming suffix characters from the original
            str = trimmed
            while !str.isEmpty {
                if DateParser.parse(str) != nil { return str }
                str.removeLast()
            }
            // Try trimming both ends
            var leftIdx = trimmed.startIndex
            var rightIdx = trimmed.endIndex
            while leftIdx < rightIdx {
                let candidate = String(trimmed[leftIdx..<rightIdx])
                if DateParser.parse(candidate) != nil { return candidate }
                leftIdx = trimmed.index(after: leftIdx)
            }
            leftIdx = trimmed.startIndex
            rightIdx = trimmed.index(before: trimmed.endIndex)
            while leftIdx < rightIdx {
                let candidate = String(trimmed[leftIdx..<rightIdx])
                if DateParser.parse(candidate) != nil { return candidate }
                rightIdx = trimmed.index(before: rightIdx)
            }
        }

        // Strategy 3: Extract numeric sequences (potential timestamps)
        // "abc1704067200def" → "1704067200"
        // Skip short numbers (≤6 digits) if date indicators exist in the input —
        // they're likely part of a date, not a standalone timestamp.
        let hasDateIndicators = input.contains(where: { dateIndicators.contains($0) })
        let numericPattern = "-?\\d+(\\.\\d+)?"
        let numericRanges = input.ranges(of: numericPattern, options: .regularExpression)
        let sortedRanges = numericRanges.sorted { a, b in
            let lenA = input.distance(from: a.lowerBound, to: a.upperBound)
            let lenB = input.distance(from: b.lowerBound, to: b.upperBound)
            if lenA != lenB { return lenA > lenB }
            return a.lowerBound < b.lowerBound
        }
        for range in sortedRanges {
            let candidate = String(input[range])
            // Skip short numbers when date indicators are present (e.g., "2024" in "2024年6月20日")
            if hasDateIndicators && candidate.count <= 6 && !candidate.contains(".") {
                continue
            }
            if TimestampDetector.detect(candidate) != nil {
                return candidate
            }
        }

        // Strategy 4: Split by whitespace/punctuation and try each token
        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        for token in tokens {
            let str = String(token)
            if TimestampDetector.detect(str) != nil || DateParser.parse(str) != nil {
                return str
            }
        }

        return nil
    }
}

// Helper extension for String ranges with regex
extension String {
    func ranges(of pattern: String, options: NSString.CompareOptions = []) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var start = startIndex
        while let range = range(of: pattern, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
}
