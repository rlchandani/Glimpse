import os

enum AppLogger {
    static let general = Logger(subsystem: "com.rohit.Glimpse", category: "general")
    static let preferences = Logger(subsystem: "com.rohit.Glimpse", category: "preferences")
    static let calendar = Logger(subsystem: "com.rohit.Glimpse", category: "calendar")
    static let statusItem = Logger(subsystem: "com.rohit.Glimpse", category: "statusItem")
}
