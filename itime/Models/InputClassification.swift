import Foundation

/// Classification result for user input.
enum InputClassification: Sendable, Equatable {
    case unixTimestamp(unit: TimestampUnit)
    case dateString(format: String)
    case unrecognized
}

/// The detected precision of a Unix timestamp.
enum TimestampUnit: String, Sendable, Codable, Equatable {
    case seconds
    case milliseconds
    case microseconds

    var divisor: Double {
        switch self {
        case .seconds: return 1
        case .milliseconds: return 1_000
        case .microseconds: return 1_000_000
        }
    }

    var displayName: String {
        switch self {
        case .seconds: return "秒"
        case .milliseconds: return "毫秒"
        case .microseconds: return "微秒"
        }
    }
}
