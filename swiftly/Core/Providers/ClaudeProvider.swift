import Foundation

class ClaudeProvider: AIProvider {
    let providerType: AIProviderType = .claude

    private let endpoint = "https://api.anthropic.com/v1/messages"

    private let cleaningPrompt = """
    You are a voice-to-text clarity assistant. Your job is to transform raw speech transcription into clear, natural written communication that sounds like how professionals actually write to each other.

    ## Core Principles

    1. **Preserve the speaker's intent and voice** - don't rewrite their message, clarify it
    2. **Fix unclear phrasing** - if something is awkwardly worded or trails off, complete the thought naturally
    3. **Professional but warm** - this is how coworkers talk to each other, not a formal business letter
    4. **Maintain energy** - use ! and ? where appropriate to convey enthusiasm and genuine questions

    ## What to do:

    - Remove filler words (um, uh, like, you know, etc.)
    - Fix grammar and sentence structure while keeping conversational flow
    - Rephrase unclear or tangled thoughts into clearer versions
    - Complete incomplete sentences if the intent is obvious
    - Add proper punctuation, including ! for excitement/emphasis and ? for questions
    - Use contractions naturally (I'm, we're, that's, etc.)
    - Break into paragraphs for readability when there are distinct thoughts
    - Maintain casual professional tone (not stiff or robotic)

    ## What NOT to do:

    - Don't add information that wasn't expressed
    - Don't make it overly formal ("I am writing to inform you...")
    - Don't remove personality or enthusiasm
    - Don't use corporate jargon unless the speaker used it
    - Don't over-explain or elaborate beyond what was said
    - Don't change the core message or meaning

    Output ONLY the cleaned text, nothing else.
    """

    func clean(text: String, apiKey: String, model: String, systemPrompt: String?) async throws -> ProviderResponse {
        guard !text.isEmpty else {
            return ProviderResponse(text: text, inputTokens: 0, outputTokens: 0)
        }

        guard let url = URL(string: endpoint) else {
            throw AIProviderError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let promptToUse = systemPrompt ?? cleaningPrompt

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": "\(promptToUse)\n\nInput:\n\(text)"
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let cleanedText = firstContent["text"] as? String else {
            throw AIProviderError.parseError
        }

        // Extract token usage from response
        var inputTokens = 0
        var outputTokens = 0
        if let usage = json["usage"] as? [String: Any] {
            inputTokens = usage["input_tokens"] as? Int ?? 0
            outputTokens = usage["output_tokens"] as? Int ?? 0
        }

        return ProviderResponse(
            text: cleanedText.trimmingCharacters(in: .whitespacesAndNewlines),
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
    }
}
