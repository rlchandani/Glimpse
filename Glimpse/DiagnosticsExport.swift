import AppKit
import Foundation
import GlimpseCore

enum DiagnosticsExport {
    static func export() async throws -> URL {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "Glimpse-Diagnostics-\(timestamp).txt"
        let fileURL = desktopURL.appendingPathComponent(fileName)

        var lines: [String] = []

        // Header
        lines.append("=== Glimpse Diagnostics ===")
        lines.append("Date: \(Date())")
        lines.append("App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
        lines.append("Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
        lines.append("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("")

        // Preferences
        lines.append("=== Preferences ===")
        let prefs = PreferencesClient.liveValue
        lines.append("Start of weekday: \(prefs.loadStartOfWeekday())")
        lines.append("Workdays: \(prefs.loadWorkdays().sorted())")
        lines.append("Display options: \(prefs.loadDisplayOptions())")
        lines.append("AI search enabled: \(prefs.loadShowAISearch())")
        lines.append("AI provider: \(prefs.loadAIProvider().rawValue)")
        lines.append("Hotkey enabled: \(UserDefaults.standard.bool(forKey: "hotkeyEnabled"))")
        lines.append("Hotkey combo: \(HotkeyCombo.load().displayString)")
        lines.append("")

        // AI Provider
        lines.append("=== AI Provider ===")
        lines.append("Active provider: \(AIDateHelper.providerName())")
        lines.append("")

        // Entitlements
        lines.append("=== Calendar Access ===")
        let status = EventKitClient.liveValue.authorizationStatus()
        lines.append("EventKit authorization: \(status.rawValue)")
        lines.append("")

        // System logs (last 5 minutes)
        lines.append("=== Recent Logs (last 5 min) ===")
        let logProcess = Process()
        logProcess.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        logProcess.arguments = [
            "show", "--predicate",
            "process == \"Glimpse\"",
            "--last", "5m", "--style", "compact",
        ]
        let pipe = Pipe()
        logProcess.standardOutput = pipe
        logProcess.standardError = pipe
        try logProcess.run()
        let logData = await withCheckedContinuation { (continuation: CheckedContinuation<Data, Never>) in
            logProcess.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: data)
            }
        }
        let logOutput = String(data: logData, encoding: .utf8) ?? "(no logs)"
        lines.append(logOutput)

        let content = lines.joined(separator: "\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

}
