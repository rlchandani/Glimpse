import XCTest
@testable import Glimpse

final class AppDesignTests: XCTestCase {

    // MARK: - Spacing

    func testSpacing_valuesArePositive() {
        XCTAssertGreaterThan(AppDesign.Spacing.xs, 0)
        XCTAssertGreaterThan(AppDesign.Spacing.sm, 0)
        XCTAssertGreaterThan(AppDesign.Spacing.md, 0)
        XCTAssertGreaterThan(AppDesign.Spacing.lg, 0)
        XCTAssertGreaterThan(AppDesign.Spacing.xl, 0)
    }

    func testSpacing_ascendingOrder() {
        XCTAssertLessThan(AppDesign.Spacing.xs, AppDesign.Spacing.sm)
        XCTAssertLessThan(AppDesign.Spacing.sm, AppDesign.Spacing.md)
        XCTAssertLessThan(AppDesign.Spacing.md, AppDesign.Spacing.lg)
        XCTAssertLessThan(AppDesign.Spacing.lg, AppDesign.Spacing.xl)
    }

    // MARK: - Corner Radius

    func testCornerRadius_valuesArePositive() {
        XCTAssertGreaterThan(AppDesign.CornerRadius.sm, 0)
        XCTAssertGreaterThan(AppDesign.CornerRadius.md, 0)
        XCTAssertGreaterThan(AppDesign.CornerRadius.lg, 0)
        XCTAssertGreaterThan(AppDesign.CornerRadius.xl, 0)
    }

    // MARK: - Grid

    func testGrid_cellHeightIsReasonable() {
        XCTAssertGreaterThanOrEqual(AppDesign.Grid.cellHeight, 20)
        XCTAssertLessThanOrEqual(AppDesign.Grid.cellHeight, 50)
    }

    func testGrid_todayCircleFitsCellHeight() {
        XCTAssertLessThanOrEqual(AppDesign.Grid.todayCircleSize, AppDesign.Grid.cellHeight)
    }

    func testGrid_opacityValuesInRange() {
        XCTAssertGreaterThan(AppDesign.Grid.borderOpacity, 0)
        XCTAssertLessThanOrEqual(AppDesign.Grid.borderOpacity, 1)
        XCTAssertGreaterThan(AppDesign.Grid.monthBorderOpacity, 0)
        XCTAssertLessThanOrEqual(AppDesign.Grid.monthBorderOpacity, 1)
    }

    // MARK: - Status Item

    func testStatusItem_heightIsReasonable() {
        XCTAssertGreaterThanOrEqual(AppDesign.StatusItem.height, 22)
        XCTAssertLessThanOrEqual(AppDesign.StatusItem.height, 40)
    }

    // MARK: - Icon

    func testIcon_menuBarSizeIsStandard() {
        XCTAssertEqual(AppDesign.Icon.menuBarSize, 18)
    }

    // MARK: - Caret

    func testCaret_widthIsReasonable() {
        XCTAssertGreaterThan(AppDesign.Caret.width, 10)
        XCTAssertLessThan(AppDesign.Caret.width, 40)
    }

    func testCaret_tipRadiusIsSmall() {
        XCTAssertGreaterThan(AppDesign.Caret.tipRadius, 0)
        XCTAssertLessThan(AppDesign.Caret.tipRadius, AppDesign.Caret.width / 2)
    }
}
