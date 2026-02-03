import SwiftUI

struct StatusIndicatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var dotOpacity: Double = 1.0
    @State private var meterLevels: [CGFloat] = [0.3, 0.5, 0.7, 0.5, 0.3]

    private let notchWidth: CGFloat = 180
    private let expandedWidth: CGFloat = 280
    private let notchHeight: CGFloat = 32

    var body: some View {
        ZStack {
            // Notch-style background shape - pitch black to match MacBook notch
            NotchShape()
                .fill(Color(red: 0, green: 0, blue: 0))
                .frame(
                    width: isExpanded ? expandedWidth : notchWidth,
                    height: notchHeight
                )

            // Content inside the notch
            if isExpanded {
                HStack(spacing: 0) {
                    // Left side - custom recording icon
                    Image(nsImage: NSImage(named: "RecordingIcon") ?? NSImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .opacity(dotOpacity)
                        .padding(.leading, 20)

                    Spacer()

                    // Right side - voice meter bars
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(meterColor)
                                .frame(width: 3, height: meterLevels[index] * 16)
                        }
                    }
                    .padding(.trailing, 24)
                }
                .frame(width: expandedWidth)
                .transition(.opacity)
            }
        }
        .frame(width: expandedWidth, height: notchHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
        .onChange(of: appState.status) { _, newStatus in
            handleStatusChange(newStatus)
        }
        .onAppear {
            handleStatusChange(appState.status)
        }
    }

    private var meterColor: Color {
        switch appState.status {
        case .recording:
            return .purple
        case .processing:
            return .white.opacity(0.7)
        case .done:
            return .green
        case .error:
            return .red
        default:
            return .gray
        }
    }

    private func handleStatusChange(_ status: DictationStatus) {
        print("[Notch UI] StatusIndicatorView: handleStatusChange called with status=\(status)")
        switch status {
        case .recording:
            print("[Notch UI] StatusIndicatorView: Expanding notch for recording")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isExpanded = true
            }
            startBlinkingDot()
            startMeterAnimation()
        case .processing:
            stopBlinkingDot()
            startProcessingAnimation()
        case .done:
            stopAllAnimations()
            showSuccessState()
        case .error:
            stopAllAnimations()
        case .idle, .initializing:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = false
            }
            stopAllAnimations()
        }
    }

    private func startBlinkingDot() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            dotOpacity = 0.3
        }
    }

    private func stopBlinkingDot() {
        withAnimation(.easeInOut(duration: 0.2)) {
            dotOpacity = 1.0
        }
    }

    private func startMeterAnimation() {
        animateMeter()
    }

    private func animateMeter() {
        guard appState.status == .recording else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            meterLevels = (0..<5).map { _ in CGFloat.random(in: 0.2...1.0) }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            if appState.status == .recording {
                animateMeter()
            }
        }
    }

    private func startProcessingAnimation() {
        animateProcessing()
    }

    private func animateProcessing() {
        guard appState.status == .processing else { return }

        // Wave animation from left to right
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                guard appState.status == .processing else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    meterLevels[i] = 0.9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    guard appState.status == .processing else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        meterLevels[i] = 0.3
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            if appState.status == .processing {
                animateProcessing()
            }
        }
    }

    private func showSuccessState() {
        withAnimation(.easeInOut(duration: 0.2)) {
            meterLevels = [0.6, 0.8, 1.0, 0.8, 0.6]
        }
    }

    private func stopAllAnimations() {
        withAnimation(.easeInOut(duration: 0.2)) {
            dotOpacity = 1.0
            meterLevels = [0.3, 0.5, 0.7, 0.5, 0.3]
        }
    }
}

// Custom shape that mimics the MacBook notch
struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let topCornerRadius: CGFloat = 4

        var path = Path()

        // Start from top-left with small corner
        path.move(to: CGPoint(x: topCornerRadius, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - topCornerRadius, y: 0))

        // Top-right small corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: topCornerRadius),
            control: CGPoint(x: rect.width, y: 0)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: topCornerRadius))

        // Top-left small corner
        path.addQuadCurve(
            to: CGPoint(x: topCornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        return path
    }
}
