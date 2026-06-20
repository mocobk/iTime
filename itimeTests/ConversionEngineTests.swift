import XCTest
@testable import itime

final class ConversionEngineTests: XCTestCase {

    // MARK: - Timestamp → Date

    func testTimestampToDate() {
        let result = ConversionEngine.convert("1704067200")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .timestampToDate)
        XCTAssertEqual(result!.input, "1704067200")
        XCTAssertTrue(result!.output.contains("2024"))
        // timestamp→date should NOT have secondaryOutput
        XCTAssertNil(result!.secondaryOutput)
    }

    func testMillisecondsTimestampToDate() {
        let result = ConversionEngine.convert("1718856384000")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .timestampToDate)
        XCTAssertNil(result!.secondaryOutput)
    }

    func testMicrosecondsTimestampToDate() {
        let result = ConversionEngine.convert("1718856384000000")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .timestampToDate)
        XCTAssertNil(result!.secondaryOutput)
    }

    // MARK: - Date → Timestamp (with secondaryOutput)

    func testISODateToTimestamp() {
        let result = ConversionEngine.convert("2024-06-20T08:26:24+08:00")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)
        XCTAssertNotNil(result!.secondaryOutput, "Date→timestamp must include secondaryOutput")
    }

    func testDateToTimestampShowsBothPrecisions() {
        let result = ConversionEngine.convert("2024-06-20 08:26:24")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)

        // Primary output should be seconds (default)
        XCTAssertEqual(result!.output.count, 10, "Default output should be 10-digit seconds")

        // Secondary output should be milliseconds
        XCTAssertNotNil(result!.secondaryOutput)
        XCTAssertEqual(result!.secondaryOutput!.count, 13, "Secondary output should be 13-digit milliseconds")
    }

    func testDateToTimestampMillisPrecision() {
        let result = ConversionEngine.convert("2024-06-20 08:26:24", outputPrecision: .milliseconds)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)

        // Primary should be milliseconds when requested
        XCTAssertEqual(result!.output.count, 13, "Primary should be milliseconds")

        // Secondary should be seconds
        XCTAssertNotNil(result!.secondaryOutput)
        XCTAssertEqual(result!.secondaryOutput!.count, 10, "Secondary should be seconds")
    }

    func testChineseDateToTimestamp() {
        let result = ConversionEngine.convert("2024年6月20日")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)
        XCTAssertNotNil(result!.secondaryOutput)
    }

    func testDashDateToTimestamp() {
        let result = ConversionEngine.convert("2024-06-20 08:26:24")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)
        XCTAssertNotNil(result!.secondaryOutput)
    }

    func testSlashDateToTimestamp() {
        let result = ConversionEngine.convert("2024/06/20 08:26:24")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .dateToTimestamp)
        XCTAssertNotNil(result!.secondaryOutput)
    }

    func testCompactDateTime14Digits() {
        // 14-digit strings are classified as microsecond timestamps first
        // (timestamp detection runs before date parsing)
        let result = ConversionEngine.convert("20240620082624")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .timestampToDate)
    }

    func testCompactDateOnly8Digits() {
        // 8-digit strings: timestamp detector sees 8 digits = seconds range
        // so "20240620" is treated as a seconds timestamp, not a compact date
        let result = ConversionEngine.convert("20240620")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.direction, .timestampToDate)
    }

    // MARK: - Unrecognized Input

    func testUnrecognizedInput() {
        XCTAssertNil(ConversionEngine.convert("hello world"))
        XCTAssertNil(ConversionEngine.convert(""))
        XCTAssertNil(ConversionEngine.convert("   "))
        XCTAssertNil(ConversionEngine.convert("abc123def"))
    }

    func testSpecialCharacters() {
        XCTAssertNil(ConversionEngine.convert("@#$%"))
        // Lenient date parsing may accept some invalid dates, but pure garbage should fail
        XCTAssertNil(ConversionEngine.convert("not-a-date-at-all"))
    }

    // MARK: - Classification

    func testClassifySecondsTimestamp() {
        let classification = ConversionEngine.classify("1704067200")
        if case .unixTimestamp(let unit) = classification {
            XCTAssertEqual(unit, .seconds)
        } else {
            XCTFail("Expected seconds timestamp classification")
        }
    }

    func testClassifyMillisecondsTimestamp() {
        let classification = ConversionEngine.classify("1704067200000")
        if case .unixTimestamp(let unit) = classification {
            XCTAssertEqual(unit, .milliseconds)
        } else {
            XCTFail("Expected milliseconds timestamp classification")
        }
    }

    func testClassifyMicrosecondsTimestamp() {
        let classification = ConversionEngine.classify("1704067200000000")
        if case .unixTimestamp(let unit) = classification {
            XCTAssertEqual(unit, .microseconds)
        } else {
            XCTFail("Expected microseconds timestamp classification")
        }
    }

    func testClassifyDateString() {
        let classification = ConversionEngine.classify("2024-06-20")
        if case .dateString = classification {
            // OK
        } else {
            XCTFail("Expected date string classification")
        }
    }

    func testClassifyISO8601() {
        let classification = ConversionEngine.classify("2024-01-15T10:30:00Z")
        if case .dateString = classification {
            // OK
        } else {
            XCTFail("Expected date string classification for ISO 8601")
        }
    }

    func testClassifyUnrecognized() {
        let classification = ConversionEngine.classify("hello")
        XCTAssertEqual(classification, .unrecognized)
    }

    func testClassifyEmpty() {
        XCTAssertEqual(ConversionEngine.classify(""), .unrecognized)
        XCTAssertEqual(ConversionEngine.classify("  "), .unrecognized)
    }

    // MARK: - Round Trip

    func testRoundTripTimestampToDateToTimestamp() {
        let original = "1704067200"
        let firstResult = ConversionEngine.convert(original)
        XCTAssertNotNil(firstResult)

        let secondResult = ConversionEngine.convert(firstResult!.output)
        XCTAssertNotNil(secondResult)
        XCTAssertEqual(secondResult!.direction, .dateToTimestamp)
        XCTAssertEqual(secondResult!.output, original)
    }

    func testRoundTripWithMilliseconds() {
        let original = "1704067200000"
        let firstResult = ConversionEngine.convert(original)
        XCTAssertNotNil(firstResult)
        XCTAssertEqual(firstResult!.direction, .timestampToDate)

        // Convert the date back, request milliseconds
        let secondResult = ConversionEngine.convert(firstResult!.output, outputPrecision: .milliseconds)
        XCTAssertNotNil(secondResult)
        XCTAssertEqual(secondResult!.direction, .dateToTimestamp)
        XCTAssertEqual(secondResult!.output, original)
    }

    // MARK: - Multi-Token Input (for Services Menu)

    func testMultipleTimestampsInText() {
        let text = "from=1718856384 to=1718856400"
        let tokens = text.split(whereSeparator: { $0.isWhitespace || $0 == "=" })
        var results: [ConversionResult] = []
        for token in tokens {
            if let result = ConversionEngine.convert(String(token)) {
                results.append(result)
            }
        }
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.direction == .timestampToDate })
    }
}
