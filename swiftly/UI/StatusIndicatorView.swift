import SwiftUI

struct StatusIndicatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var wavePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var processingRotation: Double = 0
    @State private var successCheckmark: Bool = false

    // Simple blob dimensions
    private let collapsedWidth: CGFloat = 220  // Wider than the real notch
    private let expandedWidth: CGFloat = 340   // How wide it grows
    private let blobHeight: CGFloat = 32       // Height of the blob
    private let cornerRadius: CGFloat = 10     // Blocky corners like real notch

    // True pitch black
    private let pitchBlack = Color(white: 0, opacity: 1)

    // Purple accent for recording
    private let recordingPurple = Color(red: 0.55, green: 0.35, blue: 0.95)

    private var currentWidth: CGFloat {
        isExpanded ? expandedWidth : collapsedWidth
    }

    var body: some View {
        ZStack {
            // ONE SOLID BLOB - square top, rounded bottom
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(pitchBlack)
            .frame(width: currentWidth, height: blobHeight)

            // Content inside the blob
            HStack(spacing: 12) {
                // Left: status indicator
                HStack(spacing: 6) {
                    if isExpanded {
                        Text(statusText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(statusTextColor)
                    }
                    leftIndicator
                        .frame(width: 16, height: 16)
                }

                if isExpanded {
                    Spacer()

                    // Right: waveform
                    rightContent
                        .frame(width: 50)
                }
            }
            .padding(.horizontal, 20)
            .frame(width: currentWidth, height: blobHeight)
        }
        .frame(width: expandedWidth, height: blobHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
        .onChange(of: appState.status) { _, newStatus in
            handleStatusChange(newStatus)
        }
        .onAppear {
            handleStatusChange(appState.status)
        }
    }

    // MARK: - Unified Content

    private var leftWingContent: some View {
        HStack(spacing: 8) {
            if isExpanded {
                Text(statusText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(statusTextColor)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            leftIndicator
                .frame(width: 20, height: 20)
        }
    }

    private var rightWingContent: some View {
        rightContent
            .frame(width: isExpanded ? 60 : 16)
    }

    // MARK: - Left Indicator

    @ViewBuilder
    private var leftIndicator: some View {
        switch appState.status {
        case .recording:
            ZStack {
                Circle()
                    .stroke(recordingPurple.opacity(0.5), lineWidth: 1.5)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)

                Circle()
                    .fill(recordingPurple)
                    .frame(width: 8, height: 8)
            }

        case .processing:
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.8)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(processingRotation))

        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.green)
                .scaleEffect(successCheckmark ? 1.0 : 0.5)
                .opacity(successCheckmark ? 1.0 : 0.0)

        case .error:
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red)

        default:
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
        }
    }

    // MARK: - Right Content

    @ViewBuilder
    private var rightContent: some View {
        switch appState.status {
        case .recording:
            FluidWaveform(phase: wavePhase, barCount: isExpanded ? 16 : 5)

        case .processing:
            FluidWaveform(phase: wavePhase, barCount: isExpanded ? 16 : 5)
                .opacity(0.5)

        case .done, .error:
            FluidWaveform(phase: 0, barCount: isExpanded ? 16 : 5)
                .opacity(0.3)

        default:
            FluidWaveform(phase: 0, barCount: 5)
                .opacity(0.2)
        }
    }

    // MARK: - Status Text

    private var statusText: String {
        switch appState.status {
        case .recording: return "REC"
        case .processing: return "..."
        case .done: return "Done"
        case .error: return "Error"
        default: return ""
        }
    }

    private var statusTextColor: Color {
        switch appState.status {
        case .recording: return recordingPurple
        case .processing: return .white.opacity(0.6)
        case .done: return .green
        case .error: return .red
        default: return .white.opacity(0.5)
        }
    }

    // MARK: - State Handlers

    private func handleStatusChange(_ status: DictationStatus) {
        switch status {
        case .recording:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = true
            }
            startRecordingAnimations()

        case .processing:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = true
            }
            stopRecordingAnimations()
            startProcessingAnimation()

        case .done:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = true
            }
            stopProcessingAnimation()
            showSuccess()

        case .error:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = true
            }
            stopAllAnimations()

        case .idle, .initializing:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = false
            }
            stopAllAnimations()
        }
    }

    private func startRecordingAnimations() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
            pulseScale = 1.6
        }
        animateWave()
    }

    private func animateWave() {
        guard appState.status == .recording || appState.status == .processing else { return }

        withAnimation(.linear(duration: 0.05)) {
            wavePhase += 0.12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            if appState.status == .recording || appState.status == .processing {
                animateWave()
            }
        }
    }

    private func stopRecordingAnimations() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseScale = 1.0
        }
    }

    private func startProcessingAnimation() {
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            processingRotation = 360
        }
        animateWave()
    }

    private func stopProcessingAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            processingRotation = 0
        }
    }

    private func showSuccess() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            successCheckmark = true
        }
    }

    private func stopAllAnimations() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseScale = 1.0
            processingRotation = 0
            successCheckmark = false
            wavePhase = 0
        }
    }
}


// MARK: - Notch Wing Shape (legacy, kept for reference)

enum WingSide {
    case left, right
}

struct NotchWingShape: Shape {
    let side: WingSide

    func path(in rect: CGRect) -> Path {
        let outerRadius: CGFloat = 10  // Bottom outer corners
        let notchRadius: CGFloat = 16   // Inner curve that matches notch curvature

        var path = Path()

        switch side {
        case .left:
            // Start at top-left (flat, flush with screen top)
            path.move(to: CGPoint(x: 0, y: 0))

            // Top edge - completely flat to blend with screen edge
            path.addLine(to: CGPoint(x: rect.width, y: 0))

            // Right edge going down (this connects to notch)
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - notchRadius))

            // Bottom-right inner curve (matches notch curvature)
            path.addQuadCurve(
                to: CGPoint(x: rect.width - notchRadius, y: rect.height),
                control: CGPoint(x: rect.width, y: rect.height)
            )

            // Bottom edge
            path.addLine(to: CGPoint(x: outerRadius, y: rect.height))

            // Bottom-left outer corner
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - outerRadius),
                control: CGPoint(x: 0, y: rect.height)
            )

            // Left edge back to top
            path.addLine(to: CGPoint(x: 0, y: 0))

        case .right:
            // Start at top-left (connects to notch, flat top)
            path.move(to: CGPoint(x: 0, y: 0))

            // Top edge - completely flat
            path.addLine(to: CGPoint(x: rect.width, y: 0))

            // Right edge going down
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - outerRadius))

            // Bottom-right outer corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width - outerRadius, y: rect.height),
                control: CGPoint(x: rect.width, y: rect.height)
            )

            // Bottom edge
            path.addLine(to: CGPoint(x: notchRadius, y: rect.height))

            // Bottom-left inner curve (matches notch curvature)
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - notchRadius),
                control: CGPoint(x: 0, y: rect.height)
            )

            // Left edge back to top
            path.addLine(to: CGPoint(x: 0, y: 0))
        }

        return path
    }
}

// MARK: - Fluid Waveform

struct FluidWaveform: View {
    let phase: CGFloat
    let barCount: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveBar(height: calculateHeight(for: index))
            }
        }
    }

    private func calculateHeight(for index: Int) -> CGFloat {
        let normalizedIndex = CGFloat(index) / CGFloat(barCount)

        let wave1 = sin((normalizedIndex * .pi * 3) + phase * 2) * 0.3
        let wave2 = sin((normalizedIndex * .pi * 5) + phase * 3.5) * 0.2
        let wave3 = sin((normalizedIndex * .pi * 2) + phase * 1.5) * 0.25

        let centerBias = 1.0 - abs(normalizedIndex - 0.5) * 1.2

        let combined = (wave1 + wave2 + wave3 + 0.5) * centerBias
        return max(0.15, min(1.0, combined))
    }
}

struct WaveBar: View {
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.white.opacity(0.85))
            .frame(width: 2, height: 3 + height * 11)
            .animation(.spring(response: 0.12, dampingFraction: 0.7), value: height)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        StatusIndicatorView()
            .environmentObject({
                let state = AppState()
                state.status = .recording
                return state
            }())
    }
    .frame(width: 500, height: 100)
}
