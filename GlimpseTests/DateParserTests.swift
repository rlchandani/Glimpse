import Foundation
import Testing
@testable import Glimpse

struct DateParserTests {

    @Test
    func extractDate_validISO() {
        let date = DateParser.extractDate(from: "2026-03-15")
        #expect(date != nil)
        let cal = Calendar.current
        #expect(cal.component(.year, from: date!) == 2026)
        #expect(cal.component(.month, from: date!) == 3)
        #expect(cal.component(.day, from: date!) == 15)
    }

    @Test
    func extractDate_embeddedInText() {
        let date = DateParser.extractDate(from: "The date is 2026-12-25 for Christmas")
        #expect(date != nil)
        let cal = Calendar.current
        #expect(cal.component(.month, from: date!) == 12)
        #expect(cal.component(.day, from: date!) == 25)
    }

    @Test
    func extractDate_withWhitespace() {
        let date = DateParser.extractDate(from: "  2026-01-01  \n")
        #expect(date != nil)
    }

    @Test
    func extractDate_invalidFormat() {
        #expect(DateParser.extractDate(from: "March 15, 2026") == nil)
    }

    @Test
    func extractDate_emptyString() {
        #expect(DateParser.extractDate(from: "") == nil)
    }

    @Test
    func extractDate_gibberish() {
        #expect(DateParser.extractDate(from: "not a date at all") == nil)
    }
}
