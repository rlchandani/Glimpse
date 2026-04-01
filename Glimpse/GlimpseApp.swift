import AppKit
import GlimpseCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarStatusItem = CalendarStatusItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        calendarStatusItem.setup()
        _ = SparkleUpdater.shared
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
