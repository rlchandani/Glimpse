import Foundation

/// Configuration for the shared AI proxy server.
/// The proxy injects API keys server-side so users never handle credentials.
enum ProxyConfig {
    static let baseURL = "https://proxy.auris.workers.dev"
    static let refineEndpoint = "\(baseURL)/refine"

    /// App authentication secret, reconstructed from obfuscated bytes at runtime.
    ///
    /// Security model: XOR obfuscation is NOT cryptographic security - a determined
    /// reverse engineer can trivially recover the secret by XORing the two arrays.
    /// This only prevents casual `strings` extraction from the binary.
    ///
    /// The real protection is server-side: the proxy enforces per-device rate limits
    /// via X-Auris-Device-ID, so a leaked secret cannot be used for abuse at scale.
    /// If the secret is compromised, rotate it server-side and ship an app update.
    static var appSecret: String {
        let k: [UInt8] = [
            0x69, 0xfe, 0xcd, 0x67, 0x4d, 0xd1, 0x21, 0xf2,
            0x5a, 0xcb, 0xc0, 0xc2, 0x21, 0x6c, 0xd5, 0x12,
            0xbc, 0xd8, 0x01, 0xc8, 0x8c, 0x25, 0xa0, 0x7d,
            0x38, 0x3f, 0x60, 0x38, 0x2a, 0xa6, 0x23, 0x52,
            0x2a, 0xe7, 0x84, 0xd0, 0xd9, 0x0c, 0x01, 0xd4,
            0x70, 0x81, 0xf2, 0x20
        ]
        let s: [UInt8] = [
            0x2a, 0x99, 0xfc, 0x0d, 0x08, 0x84, 0x11, 0x99,
            0x63, 0x9b, 0x99, 0xf3, 0x0e, 0x5f, 0xb4, 0x51,
            0x8c, 0x88, 0x31, 0xbe, 0xfb, 0x44, 0xd1, 0x30,
            0x7b, 0x48, 0x50, 0x0b, 0x52, 0xe0, 0x64, 0x63,
            0x01, 0xac, 0xf4, 0xbf, 0x9b, 0x5f, 0x70, 0x90,
            0x3f, 0xe7, 0xb7, 0x1d
        ]
        return String(bytes: zip(k, s).map { $0 ^ $1 }, encoding: .utf8) ?? ""
    }

    /// Unique device identifier for rate limiting.
    static var deviceID: String {
        if let existing = UserDefaults.standard.string(forKey: "glimpse_device_id") {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "glimpse_device_id")
        return newID
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static func addAuthHeaders(to request: inout URLRequest) {
        request.setValue(appSecret, forHTTPHeaderField: "X-Auris-Secret")
        request.setValue(deviceID, forHTTPHeaderField: "X-Auris-Device-ID")
        request.setValue("Glimpse/\(appVersion)", forHTTPHeaderField: "X-Auris-Version")
    }
}
