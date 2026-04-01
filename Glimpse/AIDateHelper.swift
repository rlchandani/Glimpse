import Foundation
import GlimpseCore
import Security

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Routes AI date queries to the best available provider:
/// 1. Groq API (if key is configured) — works on any macOS 14+
/// 2. Apple FoundationModels (macOS 26+) — on-device, free
/// 3. Error if neither is available
enum AIDateHelper {
    enum Provider {
        case groq
        case foundationModels
        case none
    }

    static func activeProvider() -> Provider {
        let preference = PreferencesClient.liveValue.loadAIProvider()
        let hasGroqKey = KeychainClient.liveValue.load("groq_api_key") != nil

        switch preference {
        case .groq:
            return hasGroqKey ? .groq : .none
        case .onDevice:
            return onDeviceAvailable() ? .foundationModels : .none
        case .auto:
            if hasGroqKey { return .groq }
            if onDeviceAvailable() { return .foundationModels }
            return .none
        }
    }

    static func parseNaturalLanguageDate(_ query: String) async -> Date? {
        switch activeProvider() {
        case .groq:
            guard let key = KeychainClient.liveValue.load("groq_api_key") else { return nil }
            return await GroqProvider.parseDate(query, apiKey: key)
        case .foundationModels:
            #if canImport(FoundationModels)
            if #available(macOS 26, *) {
                return await parseWithFoundationModels(query)
            }
            #endif
            return nil
        case .none:
            return nil
        }
    }

    // MARK: - Private

    private static func onDeviceAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) { return true }
        #endif
        return false
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    private static func parseWithFoundationModels(_ query: String) async -> Date? {
        do {
            let session = LanguageModelSession()
            let today = ISO8601DateFormatter().string(from: Date())
            let prompt = "Respond with ONLY a date in yyyy-MM-dd format, nothing else. If the query is relative, today is \(today). Query: \(query)"

            let response = try await session.respond(to: prompt)
            return DateParser.extractDate(from: response.content)
        } catch {
            AppLogger.general.error("FoundationModels error: \(error.localizedDescription)")
            return nil
        }
    }
    #endif
}

// MARK: - Shared Date Parser

enum DateParser {
    static func extractDate(from text: String) -> Date? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: "\\d{4}-\\d{2}-\\d{2}"),
              let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
              let matchRange = Range(match.range, in: raw)
        else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: String(raw[matchRange]))
    }
}
