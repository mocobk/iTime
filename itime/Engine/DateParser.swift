import Foundation

/// Parses date strings in multiple formats using priority-ordered strategies.
/// Uses strict (non-lenient) parsing to reject strings with trailing non-date characters.
enum DateParser {

    /// Attempt to parse the input string as a date.
    /// Returns the parsed Date and the format name, or nil if no format matches.
    static func parse(_ input: String) -> (Date, String)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try ISO 8601 formats first (most unambiguous)
        if let result = tryISO8601(trimmed) {
            return result
        }

        // Try structured date formats in priority order
        for strategy in strategies {
            if let date = strategy.formatter.date(from: trimmed) {
                return (date, strategy.name)
            }
        }

        return nil
    }

    /// Parse a date string STRICTLY, rejecting strings with trailing non-date characters.
    /// Verifies the entire string was consumed by formatting the date back and comparing.
    static func parseStrict(_ input: String) -> (Date, String)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try ISO 8601 formats — but verify entire string was consumed by formatting back
        if let result = tryISO8601Strict(trimmed) {
            return result
        }

        // Try each format strategy with strict verification
        for strategy in strategies {
            if let date = strategy.formatter.date(from: trimmed) {
                // Verify: format the date back using the SAME formatter and compare
                // If the formatted string equals the input, the entire string was consumed.
                // If it differs, only a prefix was consumed (trailing chars present).
                let formattedBack = strategy.formatter.string(from: date)
                if formattedBack == trimmed {
                    return (date, strategy.name)
                }
            }
        }

        return nil
    }

    // MARK: - ISO 8601 (Strict)

    /// Strict ISO 8601 parsing: verifies the entire string was consumed by formatting back.
    /// ISO8601DateFormatter can parse partial strings (e.g. "2025-06-20 09:00:01其余字符"
    /// matches the date-only format), so we must verify the formatted output equals the input.
    private static func tryISO8601Strict(_ input: String) -> (Date, String)? {
        // ISO 8601 with timezone: "2024-01-15T10:30:00Z" or "+08:00"
        if let date = iso8601FullFormatter.date(from: input) {
            let formattedBack = iso8601FullFormatter.string(from: date)
            if formattedBack == input {
                return (date, "ISO8601")
            }
        }
        // ISO 8601 date + time without timezone
        if let date = iso8601NoTZFormatter.date(from: input) {
            let formattedBack = iso8601NoTZFormatter.string(from: date)
            if formattedBack == input {
                return (date, "ISO8601")
            }
        }
        // ISO 8601 date only
        if let date = iso8601DateFormatter.date(from: input) {
            let formattedBack = iso8601DateFormatter.string(from: date)
            if formattedBack == input {
                return (date, "ISO8601")
            }
        }
        return nil
    }

    // MARK: - ISO 8601

    private static func tryISO8601(_ input: String) -> (Date, String)? {
        // ISO 8601 with timezone: "2024-01-15T10:30:00Z" or "+08:00"
        if let date = iso8601FullFormatter.date(from: input) {
            return (date, "ISO8601")
        }
        // ISO 8601 date + time without timezone
        if let date = iso8601NoTZFormatter.date(from: input) {
            return (date, "ISO8601")
        }
        // ISO 8601 date only
        if let date = iso8601DateFormatter.date(from: input) {
            return (date, "ISO8601")
        }
        return nil
    }

    // MARK: - Cached Formatters

    /// POSIX locale prevents user locale from interfering with format parsing.
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let chineseLocale = Locale(identifier: "zh_CN")

    private static let iso8601FullFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoTZFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return f
    }()

    private static let iso8601DateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate]
        return f
    }()

    private static func makeFormatter(
        _ format: String,
        locale: Locale? = nil
    ) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = locale ?? posixLocale
        // Strict parsing: rejects strings with trailing non-date characters
        f.isLenient = false
        return f
    }

    // MARK: - Priority-Ordered Strategies

    private struct Strategy {
        let name: String
        let formatter: DateFormatter
    }

    private static let strategies: [Strategy] = [
        // Chinese dates (need zh_CN locale)
        Strategy(name: "中文完整", formatter: makeFormatter(DateFormatStrings.chineseFull, locale: chineseLocale)),
        Strategy(name: "中文日期", formatter: makeFormatter(DateFormatStrings.chineseMedium, locale: chineseLocale)),
        Strategy(name: "中文短日期", formatter: makeFormatter(DateFormatStrings.chineseShort, locale: chineseLocale)),
        Strategy(name: "中文短日期带时间", formatter: makeFormatter(DateFormatStrings.chineseShortWithTime, locale: chineseLocale)),
        Strategy(name: "中文完整短格式", formatter: makeFormatter("yyyy年M月d日 H:mm:ss", locale: chineseLocale)),

        // Slash-separated (double-digit, then single-digit)
        Strategy(name: "斜杠日期时间", formatter: makeFormatter(DateFormatStrings.slashFull)),
        Strategy(name: "斜杠日期时间短格式", formatter: makeFormatter(DateFormatStrings.slashFullShort)),
        Strategy(name: "斜杠日期", formatter: makeFormatter(DateFormatStrings.slashDate)),
        Strategy(name: "斜杠日期短格式", formatter: makeFormatter(DateFormatStrings.slashDateShort)),

        // Dot-separated (double-digit, then single-digit)
        Strategy(name: "点分隔日期时间", formatter: makeFormatter(DateFormatStrings.dotFull)),
        Strategy(name: "点分隔日期时间短格式", formatter: makeFormatter(DateFormatStrings.dotFullShort)),
        Strategy(name: "点分隔日期", formatter: makeFormatter(DateFormatStrings.dotDate)),
        Strategy(name: "点分隔日期短格式", formatter: makeFormatter(DateFormatStrings.dotDateShort)),

        // English natural (need en_US locale)
        Strategy(name: "英文完整", formatter: makeFormatter(DateFormatStrings.englishFull, locale: Locale(identifier: "en_US"))),
        Strategy(name: "英文短日期", formatter: makeFormatter(DateFormatStrings.englishShort, locale: Locale(identifier: "en_US"))),
        Strategy(name: "RFC2822", formatter: makeFormatter(DateFormatStrings.englishRFC, locale: Locale(identifier: "en_US"))),

        // Compact
        Strategy(name: "紧凑日期时间", formatter: makeFormatter(DateFormatStrings.compactFull)),
        Strategy(name: "紧凑日期", formatter: makeFormatter(DateFormatStrings.compactDate)),

        // Dash date with time (non-ISO, no T separator)
        Strategy(name: "横线日期时间", formatter: makeFormatter(DateFormatStrings.dashFull)),
        Strategy(name: "横线日期时间短格式", formatter: makeFormatter(DateFormatStrings.dashFullShort)),
        Strategy(name: "横线日期", formatter: makeFormatter("yyyy-MM-dd")),
        Strategy(name: "横线日期短格式", formatter: makeFormatter("yyyy-M-d")),

        // Time only (assumes today's date)
        Strategy(name: "时间", formatter: makeFormatter(DateFormatStrings.timeFull)),
        Strategy(name: "短时间", formatter: makeFormatter(DateFormatStrings.timeShort)),
    ]
}
