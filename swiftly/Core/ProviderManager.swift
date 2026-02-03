import Foundation

class ProviderManager {
    static let shared = ProviderManager()

    private let providers: [AIProviderType: AIProvider] = [
        .claude: ClaudeProvider(),
        .openai: OpenAIProvider(),
        .gemini: GeminiProvider()
    ]

    private init() {}

    var currentProvider: AIProviderType {
        UserPreferences.shared.selectedProvider
    }

    var currentModel: String {
        UserPreferences.shared.selectedModel
    }

    var hasAPIKeyConfigured: Bool {
        KeychainManager.shared.hasAPIKey(for: currentProvider)
    }

    var hasAnyAPIKeyConfigured: Bool {
        KeychainManager.shared.hasAnyAPIKey()
    }

    func clean(text: String) async throws -> String {
        let provider = currentProvider
        let model = currentModel

        guard let apiKey = KeychainManager.shared.getAPIKey(for: provider) else {
            throw AIProviderError.noAPIKey
        }

        guard let aiProvider = providers[provider] else {
            throw AIProviderError.invalidResponse
        }

        let systemPrompt = UserPreferences.shared.isCodingMode ? UserPreferences.shared.codingModeInstructions : nil
        return try await aiProvider.clean(text: text, apiKey: apiKey, model: model, systemPrompt: systemPrompt)
    }

    func clean(text: String, using provider: AIProviderType, model: String? = nil) async throws -> String {
        let modelToUse = model ?? provider.defaultModel

        guard let apiKey = KeychainManager.shared.getAPIKey(for: provider) else {
            throw AIProviderError.noAPIKey
        }

        guard let aiProvider = providers[provider] else {
            throw AIProviderError.invalidResponse
        }

        let systemPrompt = UserPreferences.shared.isCodingMode ? UserPreferences.shared.codingModeInstructions : nil
        return try await aiProvider.clean(text: text, apiKey: apiKey, model: modelToUse, systemPrompt: systemPrompt)
    }

    func setProvider(_ provider: AIProviderType) {
        UserPreferences.shared.selectedProvider = provider
        UserPreferences.shared.selectedModel = provider.defaultModel
    }

    func setModel(_ model: String) {
        UserPreferences.shared.selectedModel = model
    }
}
