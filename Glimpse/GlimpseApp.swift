import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarStatusItem = CalendarStatusItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        calendarStatusItem.setup()
    }
}

@main
struct GlimpseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Calendar is managed by AppDelegate via NSStatusItem.
        // This empty Settings scene satisfies the App protocol requirement.
        Settings {
            EmptyView()
        }
    }
}
