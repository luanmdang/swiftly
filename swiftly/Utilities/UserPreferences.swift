import Foundation

class UserPreferences {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedProvider = "selectedProvider"
        static let selectedModel = "selectedModel"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isCodingMode = "isCodingMode"
        static let codingModeInstructions = "codingModeInstructions"

        // Analytics stats
        static let totalWords = "totalWords"
        static let totalCharacters = "totalCharacters"
        static let totalTranscriptions = "totalTranscriptions"
        static let totalRecordingSeconds = "totalRecordingSeconds"
        static let totalAPITokensUsed = "totalAPITokensUsed"
        static let statsLastReset = "statsLastReset"

        // Per-provider token tracking
        static let claudeTokensUsed = "claudeTokensUsed"
        static let openaiTokensUsed = "openaiTokensUsed"
        static let geminiTokensUsed = "geminiTokensUsed"
    }

    private init() {}

    var selectedProvider: AIProviderType {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedProvider),
                  let provider = AIProviderType(rawValue: rawValue) else {
                return .gemini
            }
            return provider
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedProvider)
        }
    }

    var selectedModel: String {
        get {
            if let model = defaults.string(forKey: Keys.selectedModel), !model.isEmpty {
                return model
            }
            return selectedProvider.defaultModel
        }
        set {
            defaults.set(newValue, forKey: Keys.selectedModel)
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    var isCodingMode: Bool {
        get {
            defaults.bool(forKey: Keys.isCodingMode)
        }
        set {
            defaults.set(newValue, forKey: Keys.isCodingMode)
        }
    }

    var codingModeInstructions: String {
        get {
            if let text = defaults.string(forKey: Keys.codingModeInstructions), !text.isEmpty {
                return text
            }
            return """
            You are a voice-to-text clarity assistant for developers. Your job is to transform raw speech transcriptions into clear, actionable instructions or documentation for AI coding agents, ensuring all technical context is preserved and file references are properly tagged.

            Core Principles

            Maintain technical precision - never simplify or swap technical terms (keep things like "idempotency," "middleware," "polymorphism" exactly as said)

            Tag file references - explicitly format any mentioned file names with extensions using the @filename.extension syntax

            Action-oriented flow - structure the output so it reads like a clear instruction, bug report, or feature request

            Dev-to-dev tone - sound like a professional engineer speaking to a colleague: productive, concise, and technical

            What to do:

            Tag files: convert phrases like "the index dot js file" or "the auth controller" into @index.js or @authController.ts

            Remove filler words (um, uh, like, you know, I mean, etc.)

            Preserve jargon: keep all library names, framework terms, and architectural concepts exactly as stated

            Fix grammar and sentence structure while keeping a conversational, developer-friendly flow

            Use contractions naturally (don't, it's, we're, etc.) so it doesn’t read like a rigid manual

            Break into paragraphs or line breaks when there are distinct steps, logic blocks, or topics

            Keep urgency/enthusiasm when it’s present (use ! and ? appropriately)

            What NOT to do:

            Don't simplify: do not replace complex terms with “easier” words

            Don't guess extensions: if the extension isn't clear from context or speech, leave it as is (but if they say "dot css," use @filename.css)

            Don't add information that wasn't expressed

            Don't add code: don’t write the actual code solution unless the user explicitly dictated the code line-by-line

            Don't be overly formal: avoid phrasing like "I am requesting that you..." or "Please be advised." Keep it direct and professional

            Don't remove personality: keep the speaker’s voice, urgency, and energy intact

            Examples:

            Input: "um so go into the package dot json and like we need to update the version to 1.2.0 and then check the server dot js because I think the express port is wrong"

            Output: "Go into @package.json and update the version to 1.2.0. Then check @server.js—I think the Express port is wrong."

            Input: "hey can you look at the user service dot ts and refactor that main function to use async await instead of promises because it's looking pretty messy right now"

            Output: "Can you look at @user-service.ts and refactor the main function to use async/await instead of promises? It's looking pretty messy right now!"

            Input: "i think the hydration error is coming from the navbar component dot tsx so check the useEffect hook in there"

            Output: "I think the hydration error is coming from @NavbarComponent.tsx. Check the useEffect hook in there."

            Now transform the following transcription:
            """
        }
        set {
            defaults.set(newValue, forKey: Keys.codingModeInstructions)
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    // MARK: - Analytics Stats

    var totalWords: Int {
        get { defaults.integer(forKey: Keys.totalWords) }
        set { defaults.set(newValue, forKey: Keys.totalWords) }
    }

    var totalCharacters: Int {
        get { defaults.integer(forKey: Keys.totalCharacters) }
        set { defaults.set(newValue, forKey: Keys.totalCharacters) }
    }

    var totalTranscriptions: Int {
        get { defaults.integer(forKey: Keys.totalTranscriptions) }
        set { defaults.set(newValue, forKey: Keys.totalTranscriptions) }
    }

    var totalRecordingSeconds: Double {
        get { defaults.double(forKey: Keys.totalRecordingSeconds) }
        set { defaults.set(newValue, forKey: Keys.totalRecordingSeconds) }
    }

    var totalAPITokensUsed: Int {
        get { defaults.integer(forKey: Keys.totalAPITokensUsed) }
        set { defaults.set(newValue, forKey: Keys.totalAPITokensUsed) }
    }

    var statsLastReset: Date? {
        get { defaults.object(forKey: Keys.statsLastReset) as? Date }
        set { defaults.set(newValue, forKey: Keys.statsLastReset) }
    }

    // Per-provider token tracking
    var claudeTokensUsed: Int {
        get { defaults.integer(forKey: Keys.claudeTokensUsed) }
        set { defaults.set(newValue, forKey: Keys.claudeTokensUsed) }
    }

    var openaiTokensUsed: Int {
        get { defaults.integer(forKey: Keys.openaiTokensUsed) }
        set { defaults.set(newValue, forKey: Keys.openaiTokensUsed) }
    }

    var geminiTokensUsed: Int {
        get { defaults.integer(forKey: Keys.geminiTokensUsed) }
        set { defaults.set(newValue, forKey: Keys.geminiTokensUsed) }
    }

    func tokensUsed(for provider: AIProviderType) -> Int {
        switch provider {
        case .claude: return claudeTokensUsed
        case .openai: return openaiTokensUsed
        case .gemini: return geminiTokensUsed
        }
    }

    func addTokens(_ tokens: Int, for provider: AIProviderType) {
        switch provider {
        case .claude: claudeTokensUsed += tokens
        case .openai: openaiTokensUsed += tokens
        case .gemini: geminiTokensUsed += tokens
        }
        totalAPITokensUsed += tokens
    }

    func recordTranscription(words: Int, chars: Int, duration: Double, apiTokens: Int, provider: AIProviderType) {
        totalWords += words
        totalCharacters += chars
        totalTranscriptions += 1
        totalRecordingSeconds += duration
        addTokens(apiTokens, for: provider)
    }

    func resetStats() {
        totalWords = 0
        totalCharacters = 0
        totalTranscriptions = 0
        totalRecordingSeconds = 0
        totalAPITokensUsed = 0
        claudeTokensUsed = 0
        openaiTokensUsed = 0
        geminiTokensUsed = 0
        statsLastReset = Date()
    }
}
