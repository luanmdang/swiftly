import SwiftUI

struct AnalyticsCardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetConfirmation = false

    // Matching the polished dark palette from SettingsView
    private let cardBg = Color.white.opacity(0.03)
    private let cardBorder = Color.white.opacity(0.06)
    private let accent = Color(red: 1.0, green: 0.45, blue: 0.2)
    private let textPrimary = Color.white
    private let textSecondary = Color.white.opacity(0.5)
    private let textTertiary = Color.white.opacity(0.35)

    // Cost estimates per 1K tokens (rough averages)
    private let costPer1KTokens: [AIProviderType: Double] = [
        .claude: 0.006,   // Claude 3.5 Sonnet blended avg
        .openai: 0.005,   // GPT-4o-mini avg
        .gemini: 0.0005   // Gemini Flash
    ]

    private var stats: UserPreferences { UserPreferences.shared }

    var body: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader(icon: "chart.bar.fill", title: "Analytics")

                // Big stat tiles
                HStack(spacing: 12) {
                    statTile(value: formattedWords, label: "words")
                    statTile(value: "\(stats.totalTranscriptions)", label: "transcripts")
                    statTile(value: formattedTimeSaved, label: "saved")
                }

                // Session stats (subtle)
                if appState.sessionTranscriptions > 0 {
                    HStack {
                        Text("This session:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textTertiary)
                        Text("\(appState.sessionWords) words · \(appState.sessionTranscriptions) clips")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textSecondary)
                    }
                }

                Divider().background(cardBorder)

                // API Usage breakdown
                apiUsageSection

                // Reset button
                HStack {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                            Text("Reset Stats")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .alert("Reset Statistics?", isPresented: $showResetConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Reset", role: .destructive) {
                            UserPreferences.shared.resetStats()
                            appState.sessionWords = 0
                            appState.sessionTranscriptions = 0
                            appState.sessionAPITokens = 0
                        }
                    } message: {
                        Text("This will reset all analytics data including word counts, transcription counts, and API token usage.")
                    }

                    Spacer()

                    if let lastReset = stats.statsLastReset {
                        Text("Last reset: \(lastReset, formatter: dateFormatter)")
                            .font(.system(size: 9))
                            .foregroundColor(textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Stat Tile

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - API Usage Section

    private var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Usage")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textSecondary)

            ForEach(AIProviderType.allCases, id: \.self) { provider in
                apiUsageRow(for: provider)
            }
        }
    }

    private func apiUsageRow(for provider: AIProviderType) -> some View {
        let tokens = stats.tokensUsed(for: provider)
        let totalTokens = stats.totalAPITokensUsed
        let percentage = totalTokens > 0 ? Double(tokens) / Double(totalTokens) : 0
        let cost = Double(tokens) / 1000.0 * (costPer1KTokens[provider] ?? 0)

        return HStack(spacing: 10) {
            Text(provider.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textSecondary)
                .frame(width: 55, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(providerColor(for: provider))
                        .frame(width: geo.size.width * CGFloat(percentage), height: 6)
                }
            }
            .frame(height: 6)

            Text(String(format: "~$%.2f", cost))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(textTertiary)
                .frame(width: 45, alignment: .trailing)

            Text(String(format: "(%d%%)", Int(percentage * 100)))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(textTertiary)
                .frame(width: 35, alignment: .trailing)
        }
        .frame(height: 14)
    }

    private func providerColor(for provider: AIProviderType) -> Color {
        switch provider {
        case .claude: return Color(red: 0.85, green: 0.55, blue: 0.35)
        case .openai: return Color(red: 0.35, green: 0.75, blue: 0.55)
        case .gemini: return Color(red: 0.45, green: 0.55, blue: 0.85)
        }
    }

    // MARK: - Helpers

    private var formattedWords: String {
        formatNumber(stats.totalWords)
    }

    private var formattedTimeSaved: String {
        let averageWPM = 40.0
        let totalWords = Double(stats.totalWords)
        let minutesSaved = totalWords / averageWPM
        let hours = minutesSaved / 60.0

        if hours < 1 {
            let mins = Int(minutesSaved)
            return mins > 0 ? "~\(mins)m" : "0m"
        } else {
            return String(format: "~%.1fh", hours)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fk", Double(number) / 1_000)
        }
        return "\(number)"
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }

    // MARK: - Card Components (matching SettingsView)

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accent)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(textPrimary)
        }
    }
}
