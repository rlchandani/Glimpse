import XCTest
@testable import Glimpse

final class CalendarGridHelperTests: XCTestCase {

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - calendarDays

    func testCalendarDays_always42() {
        let cal = Calendar.current
        let date = makeDate(year: 2026, month: 3, day: 15)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)
        XCTAssertEqual(days.count, 42)
    }

    func testCalendarDays_currentMonthDaysMarked() {
        let cal = Calendar.current
        let date = makeDate(year: 2026, month: 3, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)

        let currentMonthDays = days.filter { $0.isCurrentMonth }
        XCTAssertEqual(currentMonthDays.count, 31) // March has 31 days
    }

    func testCalendarDays_february() {
        let cal = Calendar.current
        let date = makeDate(year: 2026, month: 2, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)

        let currentMonthDays = days.filter { $0.isCurrentMonth }
        XCTAssertEqual(currentMonthDays.count, 28) // 2026 is not a leap year
    }

    func testCalendarDays_februaryLeapYear() {
        let cal = Calendar.current
        let date = makeDate(year: 2028, month: 2, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)

        let currentMonthDays = days.filter { $0.isCurrentMonth }
        XCTAssertEqual(currentMonthDays.count, 29)
    }

    func testCalendarDays_respectsFirstWeekday() {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let date = makeDate(year: 2026, month: 3, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)

        // First day in grid should be a Monday
        let firstDayWeekday = cal.component(.weekday, from: days[0].date)
        XCTAssertEqual(firstDayWeekday, 2) // Monday
    }

    // MARK: - monthGridInfo

    func testMonthGridInfo_marchSundayStart() {
        // March 2026 starts on Sunday (col 0), ends on Tuesday (col 2)
        var cal = Calendar.current
        cal.firstWeekday = 1
        let date = makeDate(year: 2026, month: 3, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)
        let info = CalendarGridHelper.monthGridInfo(days: days)

        XCTAssertEqual(info.startCol, 0) // Sunday = col 0
        XCTAssertEqual(info.endCol, 2)   // Tuesday = col 2
        XCTAssertEqual(info.endRow, 4)   // 5th row (0-indexed)
    }

    func testMonthGridInfo_allDaysCurrentMonth() {
        // If somehow all days are current month (won't happen naturally),
        // ensure it returns full grid bounds
        let days = (0..<42).map { _ in
            CalendarDay(date: Date(), isCurrentMonth: true)
        }
        let info = CalendarGridHelper.monthGridInfo(days: days)
        XCTAssertEqual(info.startCol, 0)
        XCTAssertEqual(info.endCol, 6)
        XCTAssertEqual(info.endRow, 5)
    }

    func testMonthGridInfo_aprilMondayStart() {
        // April 2026 starts on Wednesday
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        let date = makeDate(year: 2026, month: 4, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)
        let info = CalendarGridHelper.monthGridInfo(days: days)

        // April 1 is Wednesday, with Monday start that's col 2
        XCTAssertEqual(info.startCol, 2)
        // April 30 is Thursday, col 3
        XCTAssertEqual(info.endCol, 3)
    }

    func testMonthGridInfo_januaryStartsMidWeek() {
        // January 2026 starts on Thursday
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday start
        let date = makeDate(year: 2026, month: 1, day: 1)
        let days = CalendarGridHelper.calendarDays(for: date, using: cal)
        let info = CalendarGridHelper.monthGridInfo(days: days)

        XCTAssertEqual(info.startCol, 4) // Thursday = col 4 with Sunday start
        XCTAssertEqual(info.endCol, 6)   // Saturday = col 6 (Jan 31)
    }
}
