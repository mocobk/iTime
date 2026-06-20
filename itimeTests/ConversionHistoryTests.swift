import XCTest
@testable import itime

@MainActor
final class ConversionHistoryTests: XCTestCase {

    func testEmptyHistory() {
        let history = ConversionHistory()
        XCTAssertTrue(history.isEmpty)
        XCTAssertNil(history.latest)
        XCTAssertEqual(history.entries.count, 0)
    }

    func testAddEntry() {
        let history = ConversionHistory()
        let result = makeResult(input: "1704067200", output: "2024-01-01 08:00:00")
        history.add(result)

        XCTAssertFalse(history.isEmpty)
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertNotNil(history.latest)
        XCTAssertEqual(history.latest?.input, "1704067200")
    }

    func testNewestFirst() {
        let history = ConversionHistory()
        let r1 = makeResult(input: "first", output: "out1")
        let r2 = makeResult(input: "second", output: "out2")

        history.add(r1)
        history.add(r2)

        XCTAssertEqual(history.latest?.input, "second")
        XCTAssertEqual(history.entries[0].input, "second")
        XCTAssertEqual(history.entries[1].input, "first")
    }

    func testMaxEntriesCap() {
        let history = ConversionHistory()
        for i in 0..<25 {
            let result = makeResult(input: "input_\(i)", output: "output_\(i)")
            history.add(result)
        }
        XCTAssertEqual(history.entries.count, ConversionHistory.maxEntries)
        // The most recent should be input_24
        XCTAssertEqual(history.latest?.input, "input_24")
    }

    func testClear() {
        let history = ConversionHistory()
        history.add(makeResult(input: "a", output: "b"))
        history.add(makeResult(input: "c", output: "d"))
        XCTAssertEqual(history.entries.count, 2)

        history.clear()
        XCTAssertTrue(history.isEmpty)
        XCTAssertEqual(history.entries.count, 0)
    }

    func testMaxEntriesValue() {
        XCTAssertEqual(ConversionHistory.maxEntries, 20)
    }

    // MARK: - Helpers

    private func makeResult(input: String, output: String) -> ConversionResult {
        ConversionResult(
            input: input,
            output: output,
            direction: .timestampToDate,
            resolvedDate: .now
        )
    }
}
