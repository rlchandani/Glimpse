import Foundation
import Testing

@testable import GlimpseCore

struct CalendarClientLiveTests {

    private let client = CalendarClient.liveValue

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: - calendarDays

    @Test
    func calendarDays_alwaysReturns42() {
        let months = [
            date(2026, 1, 1), date(2026, 2, 1), date(2026, 3, 1),
            date(2026, 6, 1), date(2026, 9, 1), date(2026, 12, 1),
        ]
        for month in months {
            let days = client.calendarDays(month, Calendar.current)
            #expect(days.count == 42, "Expected 42 days for \(month)")
        }
    }

    @Test
    func calendarDays_currentMonthDaysAreMarked() {
        let march = date(2026, 3, 15)
        let days = client.calendarDays(march, Calendar.current)
        let currentMonthDays = days.filter(\.isCurrentMonth)
        #expect(currentMonthDays.count == 31) // March has 31 days
    }

    @Test
    func calendarDays_february2026Has28Days() {
        let feb = date(2026, 2, 15)
        let days = client.calendarDays(feb, Calendar.current)
        let currentMonthDays = days.filter(\.isCurrentMonth)
        #expect(currentMonthDays.count == 28)
    }

    @Test
    func calendarDays_respectsFirstWeekday() {
        var mondayFirst = Calendar.current
        mondayFirst.firstWeekday = 2 // Monday
        let march = date(2026, 3, 15)
        let days = client.calendarDays(march, mondayFirst)
        #expect(days.count == 42)
        // First day of the grid should be a Monday
        let firstDayWeekday = mondayFirst.component(.weekday, from: days[0].date)
        #expect(firstDayWeekday == 2) // Monday
    }

    // MARK: - gridInfo

    @Test
    func gridInfo_correctForMarch2026() {
        let march = date(2026, 3, 15)
        let days = client.calendarDays(march, Calendar.current)
        let info = client.gridInfo(days)
        // March 2026 starts on Sunday (col 0), ends on Tuesday (col 2)
        #expect(info.startCol == 0)
        #expect(info.endCol == 2)
    }

    @Test
    func gridInfo_emptyDaysReturnsDefaults() {
        let info = client.gridInfo([])
        #expect(info.startCol == 0)
        #expect(info.endCol == 6)
        #expect(info.endRow == 5)
    }

    // MARK: - menuBarDateString

    @Test
    func menuBarDateString_allOptionsEnabled() {
        let options = MenuBarDisplayOptions(
            showIcon: true, showDayOfWeek: true, showMonth: true,
            showDate: true, showYear: true
        )
        let march15 = date(2026, 3, 15)
        let result = client.menuBarDateString(march15, options)
        #expect(result.contains("Sun"))
        #expect(result.contains("Mar"))
        #expect(result.contains("15"))
        #expect(result.contains("2026"))
    }

    @Test
    func menuBarDateString_dateOnly() {
        let options = MenuBarDisplayOptions(
            showIcon: false, showDayOfWeek: false, showMonth: false,
            showDate: true, showYear: false
        )
        let march15 = date(2026, 3, 15)
        let result = client.menuBarDateString(march15, options)
        #expect(result == "15")
    }

    @Test
    func menuBarDateString_nothingEnabled() {
        let options = MenuBarDisplayOptions(
            showIcon: false, showDayOfWeek: false, showMonth: false,
            showDate: false, showYear: false
        )
        let result = client.menuBarDateString(Date(), options)
        #expect(result == "")
    }
}
