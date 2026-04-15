import ComposableArchitecture
import Foundation

@DependencyClient
public struct CalendarClient: Sendable {
    public var calendarDays: @Sendable (Date, Calendar) -> [CalendarDay] = { _, _ in [] }
    public var gridInfo: @Sendable ([CalendarDay]) -> GridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
    public var menuBarDateString: @Sendable (Date, MenuBarDisplayOptions) -> String = { _, _ in "" }
}

// MARK: - Cached formatters for menu bar date string

private let menuBarDayOfWeekFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f
}()

private let menuBarMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM"
    return f
}()

private let menuBarYearFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy"
    return f
}()

extension CalendarClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            calendarDays: { displayedMonth, cal in
                guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth),
                      let firstWeek = cal.dateInterval(of: .weekOfMonth, for: monthInterval.start)
                else { return [] }

                let startDate = firstWeek.start
                var days: [CalendarDay] = []

                for offset in 0..<42 {
                    guard let date = cal.date(byAdding: .day, value: offset, to: startDate) else {
                        continue
                    }
                    let isCurrentMonth = cal.isDate(
                        date, equalTo: displayedMonth, toGranularity: .month
                    )
                    days.append(CalendarDay(date: date, isCurrentMonth: isCurrentMonth))
                }

                assert(days.count == 42, "calendarDays must produce exactly 42 cells, got \(days.count)")
                return days
            },
            gridInfo: { days in
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

                return GridInfo(startCol: startCol, endCol: endCol, endRow: endRow)
            },
            menuBarDateString: { date, options in
                var parts: [String] = []

                if options.showDayOfWeek {
                    parts.append(menuBarDayOfWeekFormatter.string(from: date))
                }

                var dateParts: [String] = []
                if options.showMonth {
                    dateParts.append(menuBarMonthFormatter.string(from: date))
                }
                if options.showDate {
                    dateParts.append("\(Calendar.current.component(.day, from: date))")
                }

                if !dateParts.isEmpty {
                    parts.append(dateParts.joined(separator: " "))
                }

                if options.showYear {
                    parts.append(menuBarYearFormatter.string(from: date))
                }

                return parts.joined(separator: ", ")
            }
        )
    }

    public static let testValue = Self()
}

extension DependencyValues {
    public var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}
