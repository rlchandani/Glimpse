import XCTest
@testable import Glimpse

final class DateIconRendererTests: XCTestCase {

    func testRender_returnsNonNilImage() {
        let image = DateIconRenderer.render()
        XCTAssertNotNil(image)
    }

    func testRender_correctSize() {
        let image = DateIconRenderer.render()
        XCTAssertEqual(image.size.width, 18)
        XCTAssertEqual(image.size.height, 18)
    }

    func testRender_isNotTemplate() {
        let image = DateIconRenderer.render()
        XCTAssertFalse(image.isTemplate)
    }

    func testRender_hasRepresentations() {
        let image = DateIconRenderer.render()
        XCTAssertFalse(image.representations.isEmpty)
    }
}
