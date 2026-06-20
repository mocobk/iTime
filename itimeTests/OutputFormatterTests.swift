import XCTest
@testable import itime

final class OutputFormatterTests: XCTestCase {

    // MARK: - Date Formatting

    func testFormatDateFromTimestamp() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let result = OutputFormatter.formatDate(from: date)
        XCTAssertTrue(result.contains("2024"))
        XCTAssertTrue(result.contains("01"))
    }

    func testFormatDateEpochZero() {
        let date = Date(timeIntervalSince1970: 0)
        let result = OutputFormatter.formatDate(from: date)
        XCTAssertTrue(result.contains("1970"))
    }

    func testFormatDateNegativeTimestamp() {
        let date = Date(timeIntervalSince1970: -86400)
        let result = OutputFormatter.formatDate(from: date)
        XCTAssertTrue(result.contains("1969"))
    }

    // MARK: - Timestamp Formatting

    func testFormatTimestampSeconds() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let result = OutputFormatter.formatTimestamp(from: date, precision: .seconds)
        XCTAssertEqual(result, "1704067200")
    }

    func testFormatTimestampMilliseconds() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let result = OutputFormatter.formatTimestamp(from: date, precision: .milliseconds)
        XCTAssertEqual(result, "1704067200000")
    }

    func testFormatTimestampEpochZero() {
        let date = Date(timeIntervalSince1970: 0)
        let sec = OutputFormatter.formatTimestamp(from: date, precision: .seconds)
        XCTAssertEqual(sec, "0")
        let mil = OutputFormatter.formatTimestamp(from: date, precision: .milliseconds)
        XCTAssertEqual(mil, "0")
    }

    // MARK: - Toast Message

    func testFormatToastMessage() {
        let result = OutputFormatter.formatToastMessage(input: "1704067200", output: "2024-01-01 08:00:00")
        XCTAssertEqual(result, "1704067200 → 2024-01-01 08:00:00")
    }

    func testFormatToastMessageLongInput() {
        let longInput = String(repeating: "1", count: 50)
        let result = OutputFormatter.formatToastMessage(input: longInput, output: "output")
        XCTAssertTrue(result.contains("→"))
    }

    // MARK: - Precision Consistency

    func testSecondsAndMillisRelationship() {
        let date = Date(timeIntervalSince1970: 1718856384)
        let secResult = OutputFormatter.formatTimestamp(from: date, precision: .seconds)
        let milResult = OutputFormatter.formatTimestamp(from: date, precision: .milliseconds)
        let secValue = Int64(secResult)!
        let milValue = Int64(milResult)!
        XCTAssertEqual(milValue, secValue * 1000)
    }

    // MARK: - OutputPrecision Properties

    func testOutputPrecisionDisplayNames() {
        XCTAssertEqual(OutputPrecision.seconds.displayName, "秒")
        XCTAssertEqual(OutputPrecision.milliseconds.displayName, "毫秒")
    }

    func testOutputPrecisionMultipliers() {
        XCTAssertEqual(OutputPrecision.seconds.multiplier, 1)
        XCTAssertEqual(OutputPrecision.milliseconds.multiplier, 1000)
    }

    func testOutputPrecisionAllCases() {
        XCTAssertEqual(OutputPrecision.allCases.count, 2)
    }
}
