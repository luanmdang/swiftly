import Foundation
import WhisperKit

class Transcriber {
    private static nonisolated let defaultModel = "base.en"
    private var whisperKit: WhisperKit?

    init() async throws {
        whisperKit = try await WhisperKit(model: Self.defaultModel)
    }

    init(modelPath: String) async throws {
        whisperKit = try await WhisperKit(modelFolder: modelPath)
    }

    func transcribe(audioData: [Float]) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw TranscriberError.notInitialized
        }

        guard !audioData.isEmpty else {
            return ""
        }

        let results = try await whisperKit.transcribe(audioArray: audioData)
        let text = results.compactMap { $0.text }.joined(separator: " ")

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    static func downloadModel(
        variant: String = defaultModel,
        progressCallback: @escaping @MainActor (Double) -> Void
    ) async throws -> URL {
        let modelPath = try await WhisperKit.download(
            variant: variant,
            progressCallback: { progress in
                Task { @MainActor in
                    progressCallback(progress.fractionCompleted)
                }
            }
        )
        return modelPath
    }

    static func isModelDownloaded(variant: String = defaultModel) -> Bool {
        let fileManager = FileManager.default
        guard let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }
        let modelDir = supportDir.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml/openai_whisper-\(variant)")
        return fileManager.fileExists(atPath: modelDir.path)
    }
}

enum TranscriberError: Error, LocalizedError {
    case notInitialized
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "WhisperKit is not initialized"
        case .downloadFailed:
            return "Failed to download speech recognition model"
        }
    }
}
