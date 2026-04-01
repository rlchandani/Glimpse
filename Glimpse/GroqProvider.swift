import Foundation

enum GroqProvider {
    static func parseDate(_ query: String, apiKey: String) async -> Date? {
        let today = ISO8601DateFormatter().string(from: Date())
        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                [
                    "role": "system",
                    "content": "Respond with ONLY a date in yyyy-MM-dd format, nothing else.",
                ],
                [
                    "role": "user",
                    "content": "If the query is relative, today is \(today). Query: \(query)",
                ],
            ],
            "temperature": 0,
            "max_tokens": 20,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
              let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                AppLogger.general.error("Groq HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String
            else { return nil }

            return DateParser.extractDate(from: content)
        } catch {
            AppLogger.general.error("Groq error: \(error.localizedDescription)")
            return nil
        }
    }
}
