import Foundation

/// Sends date-parsing prompts through the shared AI proxy.
/// The proxy injects API keys server-side — no credentials in the app.
enum ProxyProvider {
    static func parseDate(_ query: String) async -> Date? {
        let today = ISO8601DateFormatter().string(from: Date())
        let prompt = "Respond with ONLY a date in yyyy-MM-dd format, nothing else. If the query is relative, today is \(today). Query: \(query)"

        guard let url = URL(string: ProxyConfig.refineEndpoint) else { return nil }

        let body: [String: Any] = [
            "tier": "balanced",
            "prompt": prompt,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        ProxyConfig.addAuthHeaders(to: &request)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                AppLogger.general.error("Proxy HTTP \(code)")
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String
            else {
                AppLogger.general.error("Proxy: no text in response")
                return nil
            }

            return DateParser.extractDate(from: text)
        } catch {
            AppLogger.general.error("Proxy error: \(error.localizedDescription)")
            return nil
        }
    }
}
