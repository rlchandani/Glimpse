import Testing
@testable import Glimpse

struct DateIconRendererTests {

    @Test
    func render_returnsValidImage() {
        let image = DateIconRenderer.render()
        #expect(image.size.width == 18)
        #expect(image.size.height == 18)
        #expect(image.isTemplate == false)
        #expect(!image.representations.isEmpty)
    }
}
