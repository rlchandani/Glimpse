import AppIntents
import AppKit

struct ShowCalendarIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Show Glimpse Calendar"
    nonisolated(unsafe) static var description = IntentDescription("Opens the Glimpse calendar popover")
    nonisolated(unsafe) static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.calendarStatusItem.statusItemClicked()
        }
        return .result()
    }
}

struct GlimpseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCalendarIntent(),
            phrases: [
                "Show \(.applicationName)",
                "Open \(.applicationName)",
            ],
            shortTitle: "Show Calendar",
            systemImageName: "calendar"
        )
    }
}
