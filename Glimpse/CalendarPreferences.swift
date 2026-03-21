import os
import ServiceManagement
import SwiftUI

@MainActor @Observable
final class CalendarPreferences {
    static let shared = CalendarPreferences()

    var startOfWeekday: Int {
        didSet { UserDefaults.standard.set(startOfWeekday, forKey: "startOfWeekday") }
    }

    var workdays: Set<Int> {
        didSet { UserDefaults.standard.set(Array(workdays), forKey: "workdays") }
    }

    var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                    AppLogger.preferences.info("Registered for launch at login")
                } else {
                    try SMAppService.mainApp.unregister()
                    AppLogger.preferences.info("Unregistered from launch at login")
                }
            } catch {
                AppLogger.preferences.error(
                    "Failed to update launch at login: \(error.localizedDescription)"
                )
                // Revert the toggle to match actual state
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    var showDayOfWeek: Bool {
        didSet {
            UserDefaults.standard.set(showDayOfWeek, forKey: "showDayOfWeek")
            onMenuBarDisplayChanged?()
        }
    }

    var showMonth: Bool {
        didSet {
            UserDefaults.standard.set(showMonth, forKey: "showMonth")
            onMenuBarDisplayChanged?()
        }
    }

    var showDate: Bool {
        didSet {
            UserDefaults.standard.set(showDate, forKey: "showDate")
            onMenuBarDisplayChanged?()
        }
    }

    var showYear: Bool {
        didSet {
            UserDefaults.standard.set(showYear, forKey: "showYear")
            onMenuBarDisplayChanged?()
        }
    }

    var showIcon: Bool {
        didSet {
            UserDefaults.standard.set(showIcon, forKey: "showIcon")
            onMenuBarDisplayChanged?()
        }
    }

    var onMenuBarDisplayChanged: (@Sendable () -> Void)?

    private static func loadBool(_ key: String, defaultValue: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) != nil
            ? UserDefaults.standard.bool(forKey: key)
            : defaultValue
    }

    private init() {
        if UserDefaults.standard.object(forKey: "startOfWeekday") != nil {
            self.startOfWeekday = UserDefaults.standard.integer(forKey: "startOfWeekday")
        } else {
            self.startOfWeekday = 1
        }

        if let saved = UserDefaults.standard.array(forKey: "workdays") as? [Int] {
            self.workdays = Set(saved)
        } else {
            self.workdays = [2, 3, 4, 5, 6]
        }

        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showDayOfWeek = Self.loadBool("showDayOfWeek", defaultValue: true)
        self.showMonth = Self.loadBool("showMonth", defaultValue: true)
        self.showDate = Self.loadBool("showDate", defaultValue: true)
        self.showYear = Self.loadBool("showYear", defaultValue: false)
        self.showIcon = Self.loadBool("showIcon", defaultValue: true)

        AppLogger.preferences.info("Preferences loaded")
    }

    var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = startOfWeekday
        return cal
    }

    func menuBarDateString(for date: Date = Date()) -> String {
        var parts: [String] = []
        let formatter = DateFormatter()

        if showDayOfWeek {
            formatter.dateFormat = "EEE"
            parts.append(formatter.string(from: date))
        }

        var dateParts: [String] = []
        if showMonth {
            formatter.dateFormat = "MMM"
            dateParts.append(formatter.string(from: date))
        }
        if showDate {
            dateParts.append("\(Calendar.current.component(.day, from: date))")
        }

        if !dateParts.isEmpty {
            parts.append(dateParts.joined(separator: " "))
        }

        if showYear {
            formatter.dateFormat = "yyyy"
            parts.append(formatter.string(from: date))
        }

        return parts.joined(separator: ", ")
    }

    func orderedWeekdaySymbols() -> [(index: Int, symbol: String)] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { offset in
            let weekday = ((startOfWeekday - 1 + offset) % 7) + 1
            return (index: weekday, symbol: symbols[weekday - 1])
        }
    }

    func weekdayName(for weekday: Int) -> String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }

    func isWorkday(_ weekday: Int) -> Bool {
        workdays.contains(weekday)
    }

    func toggleWorkday(_ weekday: Int) {
        if workdays.contains(weekday) {
            workdays.remove(weekday)
        } else {
            workdays.insert(weekday)
        }
    }
}
