// Minimal Keychain wrapper — stores the user's own bring-your-own API key
// locally, per provider, never in UserDefaults/plist.
import Foundation
import Security

enum Keychain {
    private static func service(for provider: CloudProvider) -> String {
        "com.hikari.ibrain.api-key.\(provider.rawValue)"
    }

    static func save(_ value: String, provider: CloudProvider) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: provider),
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(provider: CloudProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: provider),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(provider: CloudProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: provider),
        ]
        SecItemDelete(query as CFDictionary)
    }
}
