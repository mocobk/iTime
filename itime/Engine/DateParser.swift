import Foundation

/// Parses date strings in multiple formats using priority-ordered strategies.
enum DateParser {

    /// Attempt to parse the input string as a date.
    /// Returns the parsed Date, or nil if no format matches.
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
        f.isLenient = true
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

        // Slash-separated
        Strategy(name: "斜杠日期时间", formatter: makeFormatter(DateFormatStrings.slashFull)),
        Strategy(name: "斜杠日期", formatter: makeFormatter(DateFormatStrings.slashDate)),

        // Dot-separated
        Strategy(name: "点分隔日期时间", formatter: makeFormatter(DateFormatStrings.dotFull)),
        Strategy(name: "点分隔日期", formatter: makeFormatter(DateFormatStrings.dotDate)),

        // English natural (need en_US locale)
        Strategy(name: "英文完整", formatter: makeFormatter(DateFormatStrings.englishFull, locale: Locale(identifier: "en_US"))),
        Strategy(name: "英文短日期", formatter: makeFormatter(DateFormatStrings.englishShort, locale: Locale(identifier: "en_US"))),
        Strategy(name: "RFC2822", formatter: makeFormatter(DateFormatStrings.englishRFC, locale: Locale(identifier: "en_US"))),

        // Compact
        Strategy(name: "紧凑日期时间", formatter: makeFormatter(DateFormatStrings.compactFull)),
        Strategy(name: "紧凑日期", formatter: makeFormatter(DateFormatStrings.compactDate)),

        // Dash date with time (non-ISO, no T separator)
        Strategy(name: "横线日期时间", formatter: makeFormatter("yyyy-MM-dd HH:mm:ss")),

        // Time only (assumes today's date)
        Strategy(name: "时间", formatter: makeFormatter(DateFormatStrings.timeFull)),
        Strategy(name: "短时间", formatter: makeFormatter(DateFormatStrings.timeShort)),
    ]
}
