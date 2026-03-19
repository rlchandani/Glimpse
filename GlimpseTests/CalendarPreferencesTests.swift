import XCTest
@testable import Glimpse

final class CalendarPreferencesTests: XCTestCase {

    private var prefs: CalendarPreferences!

    override func setUp() {
        super.setUp()
        prefs = CalendarPreferences.shared
    }

    // MARK: - menuBarDateString

    func testMenuBarDateString_allEnabled() {
        prefs.showDayOfWeek = true
        prefs.showMonth = true
        prefs.showDate = true
        prefs.showYear = true

        let result = prefs.menuBarDateString()
        // Should contain day, month, date, year separated by commas
        XCTAssertTrue(result.contains(","))
        let parts = result.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(parts.count, 3) // "Day", "Month Date", "Year"
    }

    func testMenuBarDateString_allDisabled() {
        prefs.showDayOfWeek = false
        prefs.showMonth = false
        prefs.showDate = false
        prefs.showYear = false

        let result = prefs.menuBarDateString()
        XCTAssertEqual(result, "")
    }

    func testMenuBarDateString_dayOnly() {
        prefs.showDayOfWeek = true
        prefs.showMonth = false
        prefs.showDate = false
        prefs.showYear = false

        let result = prefs.menuBarDateString()
        let validDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        XCTAssertTrue(validDays.contains(result), "Got: \(result)")
    }

    func testMenuBarDateString_monthAndDate() {
        prefs.showDayOfWeek = false
        prefs.showMonth = true
        prefs.showDate = true
        prefs.showYear = false

        let result = prefs.menuBarDateString()
        // Should be like "Mar 19"
        XCTAssertFalse(result.isEmpty)
        XCTAssertFalse(result.contains(","))
    }

    func testMenuBarDateString_yearOnly() {
        prefs.showDayOfWeek = false
        prefs.showMonth = false
        prefs.showDate = false
        prefs.showYear = true

        let result = prefs.menuBarDateString()
        let year = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(result, "\(year)")
    }

    func testMenuBarDateString_dateOnly() {
        prefs.showDayOfWeek = false
        prefs.showMonth = false
        prefs.showDate = true
        prefs.showYear = false

        let result = prefs.menuBarDateString()
        let day = Calendar.current.component(.day, from: Date())
        XCTAssertEqual(result, "\(day)")
    }

    func testMenuBarDateString_specificDate() {
        prefs.showDayOfWeek = true
        prefs.showMonth = true
        prefs.showDate = true
        prefs.showYear = false

        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let components = DateComponents(year: 2026, month: 1, day: 15)
        let date = cal.date(from: components)!

        let result = prefs.menuBarDateString(for: date)
        XCTAssertTrue(result.contains("Thu"), "Got: \(result)")
        XCTAssertTrue(result.contains("Jan"), "Got: \(result)")
        XCTAssertTrue(result.contains("15"), "Got: \(result)")
    }

    // MARK: - orderedWeekdaySymbols

    func testOrderedWeekdaySymbols_sundayStart() {
        prefs.startOfWeekday = 1
        let symbols = prefs.orderedWeekdaySymbols()
        XCTAssertEqual(symbols.count, 7)
        XCTAssertEqual(symbols[0].index, 1) // Sunday
        XCTAssertEqual(symbols[6].index, 7) // Saturday
    }

    func testOrderedWeekdaySymbols_mondayStart() {
        prefs.startOfWeekday = 2
        let symbols = prefs.orderedWeekdaySymbols()
        XCTAssertEqual(symbols[0].index, 2) // Monday
        XCTAssertEqual(symbols[6].index, 1) // Sunday
    }

    func testOrderedWeekdaySymbols_wednesdayStart() {
        prefs.startOfWeekday = 4
        let symbols = prefs.orderedWeekdaySymbols()
        XCTAssertEqual(symbols[0].index, 4) // Wednesday
        XCTAssertEqual(symbols[4].index, 1) // Sunday
    }

    // MARK: - calendar

    func testCalendar_firstWeekday() {
        prefs.startOfWeekday = 2
        XCTAssertEqual(prefs.calendar.firstWeekday, 2)

        prefs.startOfWeekday = 7
        XCTAssertEqual(prefs.calendar.firstWeekday, 7)
    }

    // MARK: - workdays

    func testToggleWorkday_add() {
        prefs.workdays = [2, 3, 4, 5, 6]
        prefs.toggleWorkday(7)
        XCTAssertTrue(prefs.workdays.contains(7))
    }

    func testToggleWorkday_remove() {
        prefs.workdays = [2, 3, 4, 5, 6]
        prefs.toggleWorkday(6)
        XCTAssertFalse(prefs.workdays.contains(6))
    }

    func testIsWorkday() {
        prefs.workdays = [2, 3, 4, 5, 6]
        XCTAssertTrue(prefs.isWorkday(2))
        XCTAssertFalse(prefs.isWorkday(1))
        XCTAssertFalse(prefs.isWorkday(7))
    }

    // MARK: - weekdayName

    func testWeekdayName() {
        XCTAssertEqual(prefs.weekdayName(for: 1), "Sunday")
        XCTAssertEqual(prefs.weekdayName(for: 2), "Monday")
        XCTAssertEqual(prefs.weekdayName(for: 7), "Saturday")
    }
}
