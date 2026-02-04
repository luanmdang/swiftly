import Foundation

enum AIProviderType: String, CaseIterable, Codable {
    case claude = "claude"
    case openai = "openai"
    case gemini = "gemini"

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .openai: return "ChatGPT"
        case .gemini: return "Gemini"
        }
    }

    var defaultModel: String {
        switch self {
        case .claude: return "claude-sonnet-4-20250514"
        case .openai: return "gpt-4o-mini"
        case .gemini: return "gemini-2.5-flash-lite"
        }
    }

    var availableModels: [String] {
        switch self {
        case .claude:
            return [
                "claude-sonnet-4-20250514",
                "claude-haiku-4-20250514",
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022"
            ]
        case .openai:
            return [
                "gpt-4o-mini",
                "gpt-4o",
                "gpt-4-turbo",
                "gpt-3.5-turbo"
            ]
        case .gemini:
            return [
                "gemini-2.5-flash-lite",
                "gemini-2.0-flash-lite",
                "gemini-2.0-flash",
                "gemini-1.5-flash",
                "gemini-1.5-pro"
            ]
        }
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-..."
        case .openai: return "sk-..."
        case .gemini: return "AIzaSy..."
        }
    }

    var apiKeyHelpURL: URL {
        switch self {
        case .claude: return URL(string: "https://console.anthropic.com/settings/keys")!
        case .openai: return URL(string: "https://platform.openai.com/api-keys")!
        case .gemini: return URL(string: "https://aistudio.google.com/app/apikey")!
        }
    }
}

struct ProviderResponse {
    let text: String
    let inputTokens: Int
    let outputTokens: Int

    var totalTokens: Int { inputTokens + outputTokens }
}

protocol AIProvider {
    var providerType: AIProviderType { get }
    func clean(text: String, apiKey: String, model: String, systemPrompt: String?) async throws -> ProviderResponse
}

enum AIProviderError: Error, LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .parseError:
            return "Failed to parse API response"
        case .noAPIKey:
            return "No API key configured"
        }
    }
}
