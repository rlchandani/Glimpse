import Foundation
import FoundationModels
import SwiftUI

@available(macOS 26, *)
enum AIDateHelper {
    static func parseNaturalLanguageDate(_ query: String) async -> Date? {
        // Use FoundationModels for natural language date parsing
        do {
            let session = LanguageModelSession()
            let prompt = """
            Parse this date query and respond with ONLY a date in ISO 8601 format (yyyy-MM-dd).
            If the query is relative (like "next Friday"), use today's date \(ISO8601DateFormatter().string(from: Date())) as reference.
            If you cannot parse it, respond with "UNKNOWN".

            Query: \(query)
            """

            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            if text == "UNKNOWN" { return nil }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return formatter.date(from: text)
        } catch {
            AppLogger.general.error("AI date parse failed: \(error.localizedDescription)")
            return nil
        }
    }
}
