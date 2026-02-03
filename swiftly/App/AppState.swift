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

    var onStatusChange: ((DictationStatus) -> Void)?
    var relaunchOnboarding: (() -> Void)?
}
