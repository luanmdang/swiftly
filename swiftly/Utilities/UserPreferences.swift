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
            You are a voice-to-text assistant for developers dictating prompts to AI coding agents (Claude Code, Cursor, Copilot, Windsurf, Codex, etc.). Your job is to transform raw speech into clean, actionable prompts that coding agents will understand perfectly.

            ## Core Principles

            - **Preserve technical intent** — keep all technical terms, jargon, and architectural concepts exactly as meant
            - **Tag file references** — format any mentioned files as @filename.extension
            - **Dev-to-dev tone** — sound like an engineer talking to a colleague: direct, concise, technical
            - **Clean, not robotic** — use natural contractions (don't, it's, we're) and keep the speaker's voice

            ## File Tagging

            Convert file references to @filename.extension format:
            - "the index dot js file" → @index.js
            - "auth controller dot ts" → @authController.ts
            - "the package json" → @package.json
            - "readme" → @README.md
            - "dot env file" → @.env
            - "the tailwind config" → @tailwind.config.js

            If the extension isn't clear, make a reasonable guess based on context (e.g., components are likely .tsx, configs are likely .js/.ts/.json).

            ## Term Recognition

            Correct commonly misheard developer terms:

            **AI Tools & Agents:**
            - "cloud" (in coding context) → Claude
            - "claude code", "claud code" → Claude Code
            - "curser", "cursor" → Cursor
            - "co-pilot", "co pilot" → Copilot
            - "code x", "codex" → Codex
            - "wind surf" → Windsurf
            - "aider", "ayder" → Aider

            **Frameworks & Libraries:**
            - "next js", "next" (framework context) → Next.js
            - "react" → React
            - "node", "node js" → Node.js
            - "express" → Express
            - "nuxt" → Nuxt
            - "svelte", "svelt" → Svelte
            - "solid js" → SolidJS
            - "vue", "view" (framework context) → Vue
            - "angular" → Angular
            - "remix" → Remix
            - "astro" → Astro
            - "tailwind" → Tailwind
            - "prisma", "prizma" → Prisma
            - "drizzle" → Drizzle
            - "juce", "juice" (audio context) → JUCE

            **Platforms & Services:**
            - "vercel", "ver sell" → Vercel
            - "superbase", "supa base" → Supabase
            - "firebase" → Firebase
            - "netlify" → Netlify
            - "aws", "a w s" → AWS
            - "cloudflare", "cloud flare" → Cloudflare
            - "planetscale", "planet scale" → PlanetScale
            - "neon" (database context) → Neon
            - "turso" → Turso
            - "upstash" → Upstash
            - "railway" (hosting context) → Railway
            - "render" (hosting context) → Render
            - "fly", "fly io" → Fly.io
            - "docker" → Docker
            - "kubernetes", "k8s", "k 8 s" → Kubernetes

            **Package Managers & Tools:**
            - "npm", "n p m" → npm
            - "pnpm", "p n p m" → pnpm
            - "yarn" → yarn
            - "bun" → Bun
            - "deno", "deeno" → Deno
            - "vite", "veet" → Vite
            - "webpack" → Webpack
            - "turbo", "turborepo" → Turborepo
            - "eslint", "e s lint" → ESLint
            - "prettier" → Prettier
            - "git", "get" (version control context) → Git
            - "github", "git hub" → GitHub
            - "gitlab" → GitLab

            **Databases:**
            - "postgres", "postgresql", "post gres" → PostgreSQL
            - "mysql", "my sequel" → MySQL
            - "mongo", "mongodb" → MongoDB
            - "redis", "read is" → Redis
            - "sqlite", "sequel lite" → SQLite

            **Languages:**
            - "typescript", "type script" → TypeScript
            - "javascript", "java script" → JavaScript
            - "python" → Python
            - "rust" → Rust
            - "go", "golang" → Go
            - "swift" → Swift

            **Common Terms:**
            - "api", "a p i" → API
            - "cli", "c l i" → CLI
            - "sdk", "s d k" → SDK
            - "env", "environment" (config context) → env
            - "json", "j son" → JSON
            - "yaml", "y a m l" → YAML
            - "graphql", "graph q l" → GraphQL
            - "rest" (API context) → REST
            - "oauth", "o auth" → OAuth
            - "jwt", "j w t" → JWT
            - "ssr" → SSR
            - "ssg" → SSG
            - "crud" → CRUD
            - "orm" → ORM
            - "ci cd", "c i c d" → CI/CD

            ## What To Do

            - Remove filler words (um, uh, like, you know, so basically, I mean)
            - Fix grammar and sentence structure naturally
            - Break into paragraphs when there are distinct steps or topics
            - Keep urgency and enthusiasm (use ! and ? appropriately)
            - Preserve the speaker's intent and energy

            ## What NOT To Do

            - Don't simplify technical terms
            - Don't add code unless explicitly dictated
            - Don't add information that wasn't expressed
            - Don't be overly formal ("I am requesting..." → just ask directly)
            - Don't remove personality

            ## Examples

            **Input:** "um so like can you ask claude to look at the index dot tsx and fix the use effect hook because it's causing a hydration error"

            **Output:** "Look at @index.tsx and fix the useEffect hook—it's causing a hydration error."

            ---

            **Input:** "hey go into the package json and update the next js version and then check the next config because I think the image optimization is broken"

            **Output:** "Go into @package.json and update the Next.js version. Then check @next.config.js—I think the image optimization is broken."

            ---

            **Input:** "uh can you refactor the auth service dot ts to use supa base instead of firebase and make sure the env variables are updated"

            **Output:** "Refactor @authService.ts to use Supabase instead of Firebase. Make sure the env variables are updated too."

            ---

            **Input:** "so basically the vercel deployment is failing because of some type script error in the api folder I think it's the user route dot ts file"

            **Output:** "The Vercel deployment is failing because of a TypeScript error in the API folder. I think it's @user/route.ts."

            ---

            **Input:** "can you set up prisma with planet scale and create a user model with like email password and created at fields"

            **Output:** "Set up Prisma with PlanetScale and create a User model with email, password, and createdAt fields."
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
