import XCTest
@testable import itime

final class TimestampDetectorTests: XCTestCase {

    // MARK: - Seconds (1-10 digits)

    func testZeroTimestamp() {
        let result = TimestampDetector.detect("0")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .seconds)
        XCTAssertEqual(date.timeIntervalSince1970, 0)
    }

    func testTypicalSecondsTimestamp() {
        // 2024-01-01 00:00:00 UTC
        let result = TimestampDetector.detect("1704067200")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .seconds)
        XCTAssertEqual(date.timeIntervalSince1970, 1704067200)
    }

    func testNegativeTimestamp() {
        // Before epoch: -86400 = 1969-12-31 00:00:00 UTC
        let result = TimestampDetector.detect("-86400")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .seconds)
        XCTAssertEqual(date.timeIntervalSince1970, -86400)
    }

    // MARK: - Milliseconds (11-13 digits)

    func testMillisecondsTimestamp() {
        let result = TimestampDetector.detect("1704067200000")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .milliseconds)
        XCTAssertEqual(date.timeIntervalSince1970, 1704067200.0, accuracy: 0.001)
    }

    func testThirteenDigitTimestamp() {
        let result = TimestampDetector.detect("1718856384000")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .milliseconds)
    }

    // MARK: - Microseconds (14-16 digits)

    func testMicrosecondsTimestamp() {
        let result = TimestampDetector.detect("1704067200000000")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .microseconds)
        XCTAssertEqual(date.timeIntervalSince1970, 1704067200.0, accuracy: 0.001)
    }

    // MARK: - Edge Cases

    func testTooManyDigits() {
        let result = TimestampDetector.detect("12345678901234567")
        XCTAssertNil(result)
    }

    func testNonNumericInput() {
        XCTAssertNil(TimestampDetector.detect("hello"))
        XCTAssertNil(TimestampDetector.detect("2024-01-15"))
        XCTAssertNil(TimestampDetector.detect("abc123"))
    }

    func testWhitespaceHandling() {
        let result = TimestampDetector.detect("  1704067200  ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.1, .seconds)
    }

    func testDecimalTimestamp() {
        let result = TimestampDetector.detect("1704067200.5")
        XCTAssertNotNil(result)
        let (date, unit) = result!
        XCTAssertEqual(unit, .seconds)
    }

    func testEmptyInput() {
        XCTAssertNil(TimestampDetector.detect(""))
        XCTAssertNil(TimestampDetector.detect("   "))
    }
}
