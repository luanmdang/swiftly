import Foundation
import Combine

enum DictationStatus: Equatable {
    case initializing
    case idle
    case recording
    case processing
    case done
    case error(String)

    var description: String {
        switch self {
        case .initializing:
            return "Initializing..."
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Processing..."
        case .done:
            return "Done"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

class AppState: ObservableObject {
    @Published var status: DictationStatus = .initializing {
        didSet {
            onStatusChange?(status)
        }
    }

    // Onboarding state
    @Published var isOnboarding: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus: String = ""

    // Session-specific stats (not persisted, resets on app launch)
    @Published var sessionWords: Int = 0
    @Published var sessionTranscriptions: Int = 0
    @Published var sessionAPITokens: Int = 0

    var onStatusChange: ((DictationStatus) -> Void)?
    var relaunchOnboarding: (() -> Void)?

    // MARK: - Formatted Stats Display

    var formattedTotalWords: String {
        formatNumber(UserPreferences.shared.totalWords)
    }

    var formattedSessionWords: String {
        formatNumber(sessionWords)
    }

    var formattedTotalTranscriptions: String {
        formatNumber(UserPreferences.shared.totalTranscriptions)
    }

    var formattedTimeSaved: String {
        let averageWPM = 40.0  // Conservative typing speed
        let totalWords = Double(UserPreferences.shared.totalWords)
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

    func recordSessionTranscription(words: Int, tokens: Int) {
        sessionWords += words
        sessionTranscriptions += 1
        sessionAPITokens += tokens
    }
}
