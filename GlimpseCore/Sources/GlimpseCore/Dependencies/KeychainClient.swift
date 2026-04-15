import ComposableArchitecture
import Foundation
import Security

/// Reads sensitive data (API keys) from the macOS Keychain.
@DependencyClient
public struct KeychainClient: Sendable {
    public var load: @Sendable (String) -> String?
}

extension KeychainClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            load: { key in
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecAttrService as String: "com.rohit.Glimpse",
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                ]

                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                guard status == errSecSuccess,
                      let data = result as? Data,
                      let string = String(data: data, encoding: .utf8)
                else { return nil }

                return string
            }
        )
    }

    public static let testValue = Self()
}

extension DependencyValues {
    public var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
