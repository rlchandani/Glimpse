import AppKit
import GlimpseCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarStatusItem = CalendarStatusItem()
    let sparkleUpdater = SparkleUpdater()

    func applicationDidFinishLaunching(_ notification: Notification) {
        calendarStatusItem.setup()
    }
}

@main
struct GlimpseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
