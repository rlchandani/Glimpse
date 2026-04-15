import AppKit
import GlimpseCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarStatusItem = CalendarStatusItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }
        calendarStatusItem.setup()
        _ = SparkleUpdater.shared
    }

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
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
