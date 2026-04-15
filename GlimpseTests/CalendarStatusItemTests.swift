import Foundation
import Testing
@testable import Glimpse

struct CalendarStatusItemTests {

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - nextMidnight computation

    @Test
    func nextMidnight_fromAfternoon_returnsTomorrowJustAfterMidnight() {
        let now = date(2026, 4, 14, 15, 30) // Apr 14 at 3:30 PM
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        #expect(cal.component(.day, from: midnight) == 15)
        #expect(cal.component(.month, from: midnight) == 4)
        #expect(cal.component(.hour, from: midnight) == 0)
        #expect(cal.component(.minute, from: midnight) == 0)
        #expect(cal.component(.second, from: midnight) == 1)
    }

    @Test
    func nextMidnight_fromLateNight_returnsTomorrowNotToday() {
        let now = date(2026, 4, 14, 23, 59) // Apr 14 at 11:59 PM
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        #expect(cal.component(.day, from: midnight) == 15)
        #expect(cal.component(.month, from: midnight) == 4)
    }

    @Test
    func nextMidnight_fromJustAfterMidnight_returnsTomorrowNotToday() {
        let now = date(2026, 4, 15, 0, 1) // Apr 15 at 12:01 AM
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        // Should be Apr 16, not Apr 15 again
        #expect(cal.component(.day, from: midnight) == 16)
        #expect(cal.component(.month, from: midnight) == 4)
    }

    @Test
    func nextMidnight_crossesMonthBoundary() {
        let now = date(2026, 4, 30, 20, 0) // Apr 30 at 8 PM
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        #expect(cal.component(.day, from: midnight) == 1)
        #expect(cal.component(.month, from: midnight) == 5)
    }

    @Test
    func nextMidnight_crossesYearBoundary() {
        let now = date(2026, 12, 31, 22, 0) // Dec 31 at 10 PM
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        #expect(cal.component(.day, from: midnight) == 1)
        #expect(cal.component(.month, from: midnight) == 1)
        #expect(cal.component(.year, from: midnight) == 2027)
    }

    @Test
    func nextMidnight_isAlwaysInTheFuture() {
        let now = date(2026, 4, 15, 12, 0)
        let midnight = CalendarStatusItem.nextMidnight(after: now)!
        #expect(midnight > now)
    }

    @Test
    func nextMidnight_fromExactMidnight_returnsTomorrowMidnight() {
        // Edge case: what if the timer fires exactly at midnight?
        let now = date(2026, 4, 15, 0, 0)
        let midnight = CalendarStatusItem.nextMidnight(after: now)!

        let cal = Calendar.current
        // Should schedule for Apr 16, not re-schedule for Apr 15
        #expect(cal.component(.day, from: midnight) == 16)
    }
}
