import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case downloading
    case permissions
    case apiSetup
    case complete
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedProvider: AIProviderType = .gemini
    @State private var apiKey: String = ""
    @State private var showApiKey: Bool = false
    @State private var saveStatus: String = ""
    @State private var isDownloading: Bool = false
    @State private var downloadError: String?
    @State private var appearAnimation: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var completionScale: CGFloat = 0.5

    var onComplete: () -> Void

    // YC Startup color palette - sophisticated dark with warm accent
    private let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.02, blue: 0.03),
            Color(red: 0.06, green: 0.05, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.45, blue: 0.2),
            Color(red: 0.9, green: 0.3, blue: 0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let accent = Color(red: 1.0, green: 0.45, blue: 0.2)
    private let cardBg = Color.white.opacity(0.03)
    private let cardBorder = Color.white.opacity(0.06)
    private let textPrimary = Color.white
    private let textSecondary = Color.white.opacity(0.5)
    private let textTertiary = Color.white.opacity(0.35)

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            // Subtle noise texture overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.02))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator dots
                stepIndicator
                    .padding(.top, 22)

                // Content with transitions
                ZStack {
                    switch currentStep {
                    case .welcome:
                        welcomeView.transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .offset(x: -30))
                        ))
                    case .downloading:
                        downloadingView.transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 30)),
                            removal: .opacity.combined(with: .offset(x: -30))
                        ))
                    case .permissions:
                        permissionsView.transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 30)),
                            removal: .opacity.combined(with: .offset(x: -30))
                        ))
                    case .apiSetup:
                        apiSetupView.transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 30)),
                            removal: .opacity.combined(with: .offset(x: -30))
                        ))
                    case .complete:
                        completeView.transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 48)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 520, height: 520)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? accent : Color.white.opacity(0.15))
                    .frame(width: step == currentStep ? 10 : 6, height: step == currentStep ? 10 : 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Capsule().fill(cardBg))
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo with glow effect
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                Image(nsImage: NSImage(named: "RecordingIcon") ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
            }
            .scaleEffect(appearAnimation ? 1 : 0.8)
            .opacity(appearAnimation ? 1 : 0)

            VStack(spacing: 8) {
                Text("Swiftly")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("Talk. Type. Done.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textSecondary)
            }
            .padding(.top, 24)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 10)

            // Feature cards
            VStack(spacing: 10) {
                featureCard(
                    icon: "option",
                    isSystemIcon: false,
                    title: "Hold Right Option",
                    subtitle: "to start recording"
                )
                featureCard(
                    icon: "waveform",
                    isSystemIcon: true,
                    title: "On-device transcription",
                    subtitle: "private & fast"
                )
                featureCard(
                    icon: "sparkles",
                    isSystemIcon: true,
                    title: "AI polish",
                    subtitle: "optional cleanup"
                )
            }
            .padding(.top, 32)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)

            Spacer()

            primaryButton("Get Started") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .downloading
                }
                startModelDownload()
            }
        }
    }

    private func featureCard(icon: String, isSystemIcon: Bool, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardBg)
                    .frame(width: 36, height: 36)

                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                } else {
                    // Keyboard key visualization
                    keyCap(icon)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
    }

    private func keyCap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(accent)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(accent.opacity(0.15))
            )
    }

    // MARK: - Downloading

    private var downloadingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated download icon
            ZStack {
                Circle()
                    .fill(accent.opacity(pulseAnimation ? 0.2 : 0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.2 : 1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(accentGradient)
                    .rotationEffect(.degrees(pulseAnimation ? 0 : 360))
            }
            .onAppear { pulseAnimation = true }
            .onDisappear { pulseAnimation = false }

            VStack(spacing: 6) {
                Text("Downloading Model")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("Speech recognition · ~140MB")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
            }
            .padding(.top, 24)

            // Progress bar
            VStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentGradient)
                            .frame(width: geo.size.width * appState.downloadProgress)
                            .animation(.spring(response: 0.3), value: appState.downloadProgress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(appState.downloadStatus)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textTertiary)

                    Spacer()

                    Text("\(Int(appState.downloadProgress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(accent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            if let error = downloadError {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)

                    secondaryButton("Retry") {
                        downloadError = nil
                        startModelDownload()
                    }
                }
                .padding(.top, 20)
            }

            Spacer()
        }
    }

    // MARK: - Permissions

    private var permissionsView: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(accentGradient)

            VStack(spacing: 6) {
                Text("Quick Permissions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("Swiftly needs these to work its magic")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
            }
            .padding(.top, 20)

            VStack(spacing: 12) {
                permissionCard(
                    icon: "keyboard.fill",
                    title: "Accessibility",
                    subtitle: "Hotkey & typing",
                    isGranted: PermissionsManager.shared.checkAccessibilityPermission()
                )

                permissionCard(
                    icon: "mic.fill",
                    title: "Microphone",
                    subtitle: "Voice recording",
                    isGranted: PermissionsManager.shared.checkMicrophonePermission()
                )
            }
            .padding(.top, 28)

            Button {
                PermissionsManager.shared.requestAccessibilityPermission()
                PermissionsManager.shared.requestMicrophonePermission { _ in }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Open System Settings")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            Spacer()

            primaryButton("Continue") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .apiSetup
                }
            }
        }
    }

    private func permissionCard(icon: String, title: String, subtitle: String, isGranted: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isGranted ? Color.green.opacity(0.15) : cardBg)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isGranted ? .green : accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(textTertiary)
            }

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isGranted ? .green : Color.white.opacity(0.2))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isGranted ? Color.green.opacity(0.2) : cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - API Setup

    private var apiSetupView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("AI Enhancement")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                Text("Optional · Cleans up your transcriptions")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
            }
            .padding(.top, 20)

            // Provider selector
            HStack(spacing: 0) {
                ForEach(AIProviderType.allCases, id: \.self) { provider in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedProvider = provider
                        }
                    } label: {
                        Text(provider.displayName)
                            .font(.system(size: 13, weight: selectedProvider == provider ? .bold : .medium))
                            .foregroundColor(selectedProvider == provider ? textPrimary : textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedProvider == provider ?
                                    RoundedRectangle(cornerRadius: 8).fill(cardBg) :
                                    RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            )
            .padding(.top, 24)

            // API Key input
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Group {
                        if showApiKey {
                            TextField("", text: $apiKey, prompt: Text(selectedProvider.apiKeyPlaceholder).foregroundColor(textTertiary))
                        } else {
                            SecureField("", text: $apiKey, prompt: Text(selectedProvider.apiKeyPlaceholder).foregroundColor(textTertiary))
                        }
                    }
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(textPrimary)

                    Button { showApiKey.toggle() } label: {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(cardBorder, lineWidth: 1)
                        )
                )

                HStack {
                    Button {
                        saveApiKeyAction()
                    } label: {
                        HStack(spacing: 4) {
                            if !saveStatus.isEmpty {
                                Image(systemName: saveStatus == "Saved!" ? "checkmark" : "xmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(saveStatus.isEmpty ? "Save" : saveStatus)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(saveStatus == "Saved!" ? .green : accent)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        NSWorkspace.shared.open(selectedProvider.apiKeyHelpURL)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Get API Key")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep = .complete
                    }
                } label: {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textTertiary)
                }
                .buttonStyle(.plain)

                primaryButton("Continue") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep = .complete
                    }
                }
            }
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(completionScale)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                    .scaleEffect(completionScale)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    completionScale = 1
                }
            }

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(textPrimary)

                HStack(spacing: 6) {
                    Text("Hold")
                        .foregroundColor(textSecondary)
                    keyCap("⌥ option")
                    Text("to start")
                        .foregroundColor(textSecondary)
                }
                .font(.system(size: 14, weight: .medium))
            }
            .padding(.top, 24)

            if !KeychainManager.shared.hasAnyAPIKey() {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(accent.opacity(0.8))
                    Text("AI cleanup disabled · Add key in Settings")
                        .font(.system(size: 12))
                        .foregroundColor(textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(0.1))
                )
                .padding(.top, 24)
            }

            Spacer()

            primaryButton("Start Using Swiftly") {
                UserPreferences.shared.hasCompletedOnboarding = true
                onComplete()
            }
        }
    }

    // MARK: - Buttons

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentGradient)
                        .shadow(color: accent.opacity(0.4), radius: 12, y: 4)
                )
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accent.opacity(0.5), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startModelDownload() {
        guard !isDownloading else { return }
        isDownloading = true
        appState.downloadStatus = "Connecting..."
        appState.downloadProgress = 0

        Task { @MainActor in
            do {
                _ = try await Transcriber.downloadModel { progress in
                    appState.downloadProgress = progress
                    if progress < 0.1 {
                        appState.downloadStatus = "Starting download..."
                    } else if progress < 1.0 {
                        appState.downloadStatus = "Downloading..."
                    } else {
                        appState.downloadStatus = "Complete!"
                    }
                }

                isDownloading = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentStep = .permissions
                }
            } catch {
                isDownloading = false
                downloadError = error.localizedDescription
            }
        }
    }

    private func saveApiKeyAction() {
        guard !apiKey.isEmpty else {
            saveStatus = "Enter key"
            clearStatusAfterDelay()
            return
        }

        if KeychainManager.shared.saveAPIKey(apiKey, for: selectedProvider) {
            UserPreferences.shared.selectedProvider = selectedProvider
            saveStatus = "Saved!"
        } else {
            saveStatus = "Failed"
        }
        clearStatusAfterDelay()
    }

    private func clearStatusAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saveStatus = "" }
        }
    }
}
