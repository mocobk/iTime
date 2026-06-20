import Foundation

/// Central conversion engine. Dispatches input to the appropriate detector/parser.
enum ConversionEngine {

    /// Convert a raw input string to a ConversionResult.
    /// Tries timestamp detection first (unambiguous), then date string parsing.
    /// Returns nil if the input cannot be recognized.
    static func convert(
        _ rawInput: String,
        outputPrecision: OutputPrecision = .seconds
    ) -> ConversionResult? {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        // Try timestamp first (pure digits are unambiguous)
        if let (date, unit) = TimestampDetector.detect(input) {
            let output = OutputFormatter.formatDate(from: date)
            return ConversionResult(
                input: input,
                output: output,
                direction: .timestampToDate,
                resolvedDate: date,
                outputPrecision: outputPrecision
            )
        }

        // Try date string parsing
        if let (date, _) = DateParser.parse(input) {
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
                input: input,
                output: primaryOutput,
                secondaryOutput: secondary,
                direction: .dateToTimestamp,
                resolvedDate: date,
                outputPrecision: outputPrecision
            )
        }

        return nil
    }

    /// Classify the input without performing conversion.
    static func classify(_ rawInput: String) -> InputClassification {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return .unrecognized }

        if let (_, unit) = TimestampDetector.detect(input) {
            return .unixTimestamp(unit: unit)
        }

        if let (_, format) = DateParser.parse(input) {
            return .dateString(format: format)
        }

        return .unrecognized
    }
}
