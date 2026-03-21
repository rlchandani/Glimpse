import SwiftUI
import Testing
@testable import Glimpse

struct MonthBorderShapeTests {

    @Test
    func path_noSteps_isClosedPath() {
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)
    }

    @Test
    func path_bottomStepOnly() {
        let shape = MonthBorderShape(startCol: 0, endCol: 2, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)

        let bounds = path.boundingRect
        #expect(bounds.maxX <= rect.maxX + 1)
        #expect(bounds.maxY <= rect.maxY + 1)
    }

    @Test
    func path_topStepOnly() {
        let shape = MonthBorderShape(startCol: 4, endCol: 6, endRow: 5)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)
    }

    @Test
    func path_bothSteps() {
        let shape = MonthBorderShape(startCol: 3, endCol: 4, endRow: 5)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)
    }

    @Test
    func path_singleRow() {
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 0)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)
    }

    @Test
    func path_monthEndsLastCol() {
        let shape = MonthBorderShape(startCol: 3, endCol: 6, endRow: 4)
        let rect = CGRect(x: 0, y: 0, width: 280, height: 180)
        let path = shape.path(in: rect)
        #expect(!path.isEmpty)
    }

    @Test
    func path_zeroSizeRect_doesNotCrash() {
        let shape = MonthBorderShape(startCol: 0, endCol: 6, endRow: 4)
        let rect = CGRect.zero
        _ = shape.path(in: rect)
    }
}
