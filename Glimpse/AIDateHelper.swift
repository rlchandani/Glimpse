import Foundation
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
enum AIDateHelper {
    static func parseNaturalLanguageDate(_ query: String) async -> Date? {
        do {
            let session = LanguageModelSession()

            let today = ISO8601DateFormatter().string(from: Date())
            let prompt = "Respond with ONLY a date in yyyy-MM-dd format, nothing else. If the query is relative, today is \(today). Query: \(query)"

            let response = try await session.respond(to: prompt)
            let raw = response.content
            NSLog("[Glimpse AI] Raw response: [%@]", raw)

            let regex = try NSRegularExpression(pattern: "\\d{4}-\\d{2}-\\d{2}")
            let range = NSRange(raw.startIndex..., in: raw)
            guard let match = regex.firstMatch(in: raw, range: range),
                  let matchRange = Range(match.range, in: raw) else {
                NSLog("[Glimpse AI] No date pattern found in response")
                return nil
            }

            let dateString = String(raw[matchRange])
            NSLog("[Glimpse AI] Parsed date string: %@", dateString)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            return formatter.date(from: dateString)
        } catch {
            NSLog("[Glimpse AI] Error: %@", error.localizedDescription)
            return nil
        }
    }
}
#endif
