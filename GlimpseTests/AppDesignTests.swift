import Testing
@testable import Glimpse

struct AppDesignTests {

    // MARK: - Spacing

    @Test
    func spacing_valuesArePositive() {
        #expect(AppDesign.Spacing.xs > 0)
        #expect(AppDesign.Spacing.sm > 0)
        #expect(AppDesign.Spacing.md > 0)
        #expect(AppDesign.Spacing.lg > 0)
        #expect(AppDesign.Spacing.xl > 0)
    }

    @Test
    func spacing_ascendingOrder() {
        #expect(AppDesign.Spacing.xs < AppDesign.Spacing.sm)
        #expect(AppDesign.Spacing.sm < AppDesign.Spacing.md)
        #expect(AppDesign.Spacing.md < AppDesign.Spacing.lg)
        #expect(AppDesign.Spacing.lg < AppDesign.Spacing.xl)
    }

    // MARK: - Corner Radius

    @Test
    func cornerRadius_valuesArePositive() {
        #expect(AppDesign.CornerRadius.sm > 0)
        #expect(AppDesign.CornerRadius.md > 0)
        #expect(AppDesign.CornerRadius.lg > 0)
        #expect(AppDesign.CornerRadius.xl > 0)
    }

    // MARK: - Grid

    @Test
    func grid_cellHeightIsReasonable() {
        #expect(AppDesign.Grid.cellHeight >= 20)
        #expect(AppDesign.Grid.cellHeight <= 50)
    }

    @Test
    func grid_todayCircleFitsCellHeight() {
        #expect(AppDesign.Grid.todayCircleSize <= AppDesign.Grid.cellHeight)
    }

    @Test
    func grid_opacityValuesInRange() {
        #expect(AppDesign.Grid.borderOpacity > 0)
        #expect(AppDesign.Grid.borderOpacity <= 1)
        #expect(AppDesign.Grid.monthBorderOpacity > 0)
        #expect(AppDesign.Grid.monthBorderOpacity <= 1)
    }

    // MARK: - Status Item

    @Test
    func statusItem_heightIsReasonable() {
        #expect(AppDesign.StatusItem.height >= 22)
        #expect(AppDesign.StatusItem.height <= 40)
    }

    // MARK: - Icon

    @Test
    func icon_menuBarSizeIsStandard() {
        #expect(AppDesign.Icon.menuBarSize == 18)
    }

    // MARK: - Caret

    @Test
    func caret_widthIsReasonable() {
        #expect(AppDesign.Caret.width > 10)
        #expect(AppDesign.Caret.width < 40)
    }

    @Test
    func caret_tipRadiusIsSmall() {
        #expect(AppDesign.Caret.tipRadius > 0)
        #expect(AppDesign.Caret.tipRadius < AppDesign.Caret.width / 2)
    }
}
