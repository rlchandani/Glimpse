import Foundation

enum CalendarGridHelper {
    static func calendarDays(
        for displayedMonth: Date,
        using cal: Calendar
    ) -> [CalendarDay] {
        guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = cal.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        let startDate = firstWeek.start
        var days: [CalendarDay] = []

        for offset in 0..<42 {
            guard let date = cal.date(byAdding: .day, value: offset, to: startDate) else {
                continue
            }
            let isCurrentMonth = cal.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            days.append(CalendarDay(date: date, isCurrentMonth: isCurrentMonth))
        }

        return days
    }

    static func monthGridInfo(
        days: [CalendarDay]
    ) -> (startCol: Int, endCol: Int, endRow: Int) {
        var startCol = 0
        var endCol = 6
        var endRow = 5

        for (i, day) in days.enumerated() {
            if day.isCurrentMonth {
                startCol = i % 7
                break
            }
        }

        for i in stride(from: days.count - 1, through: 0, by: -1) {
            if days[i].isCurrentMonth {
                endCol = i % 7
                endRow = i / 7
                break
            }
        }

        return (startCol, endCol, endRow)
    }
}
