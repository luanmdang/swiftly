import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.swiftly.apikey"

    private init() {}

    // MARK: - Multi-Provider API Key Management

    func saveAPIKey(_ apiKey: String, for provider: AIProviderType) -> Bool {
        deleteAPIKey(for: provider)

        guard let data = apiKey.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getAPIKey(for provider: AIProviderType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }

        return apiKey
    }

    @discardableResult
    func deleteAPIKey(for provider: AIProviderType) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Convenience Methods

    func hasAPIKey(for provider: AIProviderType) -> Bool {
        return getAPIKey(for: provider) != nil
    }

    func hasAnyAPIKey() -> Bool {
        return AIProviderType.allCases.contains { hasAPIKey(for: $0) }
    }

    func configuredProviders() -> [AIProviderType] {
        return AIProviderType.allCases.filter { hasAPIKey(for: $0) }
    }
}
