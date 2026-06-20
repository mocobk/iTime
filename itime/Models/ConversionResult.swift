import Foundation

/// The direction of a conversion.
enum ConversionDirection: String, Sendable, Codable {
    case timestampToDate
    case dateToTimestamp
}

/// A single conversion record.
struct ConversionResult: Identifiable, Sendable {
    let id: UUID
    let input: String
    let output: String
    /// Secondary output (e.g., milliseconds when primary is seconds).
    /// Only populated for dateToTimestamp direction.
    let secondaryOutput: String?
    let direction: ConversionDirection
    let resolvedDate: Date
    let createdAt: Date
    /// Output precision used for this conversion — determines which label
    /// applies to primary vs secondary output.
    let outputPrecision: OutputPrecision

    init(
        id: UUID = UUID(),
        input: String,
        output: String,
        secondaryOutput: String? = nil,
        direction: ConversionDirection,
        resolvedDate: Date,
        createdAt: Date = .now,
        outputPrecision: OutputPrecision = .seconds
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.secondaryOutput = secondaryOutput
        self.direction = direction
        self.resolvedDate = resolvedDate
        self.createdAt = createdAt
        self.outputPrecision = outputPrecision
    }
}
