import Foundation

public struct MenuBarDisplayOptions: Equatable, Sendable, Codable {
    public var showIcon: Bool
    public var showDayOfWeek: Bool
    public var showMonth: Bool
    public var showDate: Bool
    public var showYear: Bool
    public var showFilledBackground: Bool

    public static let `default` = MenuBarDisplayOptions(
        showIcon: true,
        showDayOfWeek: true,
        showMonth: true,
        showDate: true,
        showYear: false,
        showFilledBackground: false
    )

    public init(
        showIcon: Bool = true,
        showDayOfWeek: Bool = true,
        showMonth: Bool = true,
        showDate: Bool = true,
        showYear: Bool = false,
        showFilledBackground: Bool = false
    ) {
        self.showIcon = showIcon
        self.showDayOfWeek = showDayOfWeek
        self.showMonth = showMonth
        self.showDate = showDate
        self.showYear = showYear
        self.showFilledBackground = showFilledBackground
    }
}
