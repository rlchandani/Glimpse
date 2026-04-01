import ComposableArchitecture
import Foundation
import Security

/// Securely stores and retrieves sensitive data (API keys) via the macOS Keychain.
/// Never stores secrets in UserDefaults, files, or logs.
@DependencyClient
public struct KeychainClient: Sendable {
    public var save: @Sendable (String, String) throws -> Void
    public var load: @Sendable (String) -> String?
    public var delete: @Sendable (String) throws -> Void
}

extension KeychainClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            save: { key, value in
                // Delete existing item first
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecAttrService as String: "com.rohit.Glimpse",
                ]
                SecItemDelete(deleteQuery as CFDictionary)

                guard let data = value.data(using: .utf8) else { return }
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecAttrService as String: "com.rohit.Glimpse",
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                ]

                let status = SecItemAdd(addQuery as CFDictionary, nil)
                if status != errSecSuccess {
                    throw KeychainError.saveFailed(status)
                }
            },
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
            },
            delete: { key in
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecAttrService as String: "com.rohit.Glimpse",
                ]

                let status = SecItemDelete(query as CFDictionary)
                if status != errSecSuccess && status != errSecItemNotFound {
                    throw KeychainError.deleteFailed(status)
                }
            }
        )
    }

    public static let testValue = Self()
}

public enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .saveFailed(status): "Keychain save failed: \(status)"
        case let .deleteFailed(status): "Keychain delete failed: \(status)"
        }
    }
}

extension DependencyValues {
    public var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
