import XCTest
@testable import itime

final class DateParserTests: XCTestCase {

    // MARK: - ISO 8601

    func testISO8601WithZ() {
        let result = DateParser.parse("2024-01-15T10:30:00Z")
        XCTAssertNotNil(result)
        let (date, _) = result!
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 30)
    }

    func testISO8601WithOffset() {
        let result = DateParser.parse("2024-06-20T08:26:24+08:00")
        XCTAssertNotNil(result)
    }

    func testISO8601DateOnly() {
        let result = DateParser.parse("2024-06-20")
        XCTAssertNotNil(result)
        let (date, _) = result!
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 20)
    }

    // MARK: - Chinese Dates

    func testChineseFullDate() {
        let result = DateParser.parse("2024年06月20日 08:26:24")
        XCTAssertNotNil(result)
    }

    func testChineseShortDate() {
        let result = DateParser.parse("2024年6月20日")
        XCTAssertNotNil(result)
    }

    // MARK: - Slash Dates

    func testSlashDateTimeWithTime() {
        let result = DateParser.parse("2024/06/20 08:26:24")
        XCTAssertNotNil(result)
    }

    func testSlashDateOnly() {
        let result = DateParser.parse("2024/06/20")
        XCTAssertNotNil(result)
    }

    // MARK: - Dash Date with Time

    func testDashDateTimeWithTime() {
        let result = DateParser.parse("2024-06-20 08:26:24")
        XCTAssertNotNil(result)
    }

    // MARK: - Compact Format

    func testCompactDateTime() {
        let result = DateParser.parse("20240620082624")
        XCTAssertNotNil(result)
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        XCTAssertNil(DateParser.parse(""))
        XCTAssertNil(DateParser.parse("   "))
    }

    func testGarbageInput() {
        XCTAssertNil(DateParser.parse("hello world"))
        XCTAssertNil(DateParser.parse("not a date"))
    }
}
