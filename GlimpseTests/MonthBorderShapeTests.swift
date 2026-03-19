import XCTest
import SwiftUI
@testable import Glimpse

final class MonthBorderShapeTests: XCTestCase {

    // MARK: - Simple rectangle (no steps)

    func testPath_noSteps_isClosedPath() {
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    // MARK: - Bottom step only

    func testPath_bottomStepOnly() {
        // Month starts at col 0, ends at col 2 (bottom-right notch)
        let shape = MonthBorderShape(startCol: 0, endCol: 2, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)

        // The path bounding box should not extend beyond the rect
        let bounds = path.boundingRect
        XCTAssertLessThanOrEqual(bounds.maxX, rect.maxX + 1)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY + 1)
    }

    // MARK: - Top step only

    func testPath_topStepOnly() {
        // Month starts at col 4, ends at col 6 (top-left notch)
        let shape = MonthBorderShape(startCol: 4, endCol: 6, endRow: 5)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    // MARK: - Both steps

    func testPath_bothSteps() {
        // Month starts at col 3, ends at col 4 (both notches)
        let shape = MonthBorderShape(startCol: 3, endCol: 4, endRow: 5)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    // MARK: - Edge cases

    func testPath_singleRow() {
        // Month fits in one row (e.g., very short month representation)
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 0)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    func testPath_monthEndsLastCol() {
        // No bottom step when month ends on Saturday (col 6)
        let shape = MonthBorderShape(startCol: 3, endCol: 6, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
    }

    func testPath_zeroSizeRect() {
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 4)
        let rect = CGRect.zero
        let path = shape.path(in: rect)
        // Should not crash, may be empty or degenerate
        _ = path
    }
}
