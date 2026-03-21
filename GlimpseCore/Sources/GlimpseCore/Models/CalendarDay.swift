import Foundation

public struct CalendarDay: Equatable, Sendable {
    public let date: Date
    public let isCurrentMonth: Bool

    public init(date: Date, isCurrentMonth: Bool) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
    }
}
