import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProvider: AIProviderType = UserPreferences.shared.selectedProvider
    @State private var selectedModel: String = UserPreferences.shared.selectedModel
    @State private var apiKeys: [AIProviderType: String] = [:]
    @State private var showApiKey: [AIProviderType: Bool] = [:]
    @State private var saveStatus: [AIProviderType: SaveStatus] = [:]
    @State private var isCodingMode: Bool = UserPreferences.shared.isCodingMode
    @State private var codingModeInstructions: String = UserPreferences.shared.codingModeInstructions

    // Hover state tracking
    @State private var hoveredCard: String? = nil
    @State private var hoveredTab: AIProviderType? = nil

    enum SaveStatus {
        case idle
        case saved
        case error
    }

    // Matching the polished dark palette
    private let bgColor = Color(red: 0.04, green: 0.04, blue: 0.05)
    private let cardBg = Color.white.opacity(0.03)
    private let cardBorder = Color.white.opacity(0.06)
    private let accent = Color(red: 1.0, green: 0.45, blue: 0.2)
    private let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.2), Color(red: 0.9, green: 0.3, blue: 0.1)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let textPrimary = Color.white
    private let textSecondary = Color.white.opacity(0.5)
    private let textTertiary = Color.white.opacity(0.35)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(textPrimary)
                            Text("Configure your dictation experience")
                                .font(.system(size: 12))
                                .foregroundColor(textTertiary)
                        }
                        Spacer()
                        statusPill
                    }
                    .padding(.bottom, 8)

                    // Warning banner if no API key
                    if !KeychainManager.shared.hasAnyAPIKey() {
                        warningBanner
                    }

                    // Analytics Card
                    AnalyticsCardView()

                    // Provider Selection Card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            cardHeader(icon: "cpu", title: "AI Provider")

                            // Provider tabs
                            HStack(spacing: 0) {
                                ForEach(AIProviderType.allCases, id: \.self) { provider in
                                    providerTab(provider)
                                }
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.04))
                            )

                            // API Key Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("API Key")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(textSecondary)

                                    Spacer()

                                    if KeychainManager.shared.hasAPIKey(for: selectedProvider) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 10))
                                            Text("Configured")
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(.green)
                                    }
                                }

                                HStack(spacing: 10) {
                                    HStack {
                                        Group {
                                            let isShowing = showApiKey[selectedProvider] ?? false
                                            if isShowing {
                                                TextField("", text: binding(for: selectedProvider),
                                                         prompt: Text(selectedProvider.apiKeyPlaceholder).foregroundColor(textTertiary))
                                            } else {
                                                SecureField("", text: binding(for: selectedProvider),
                                                           prompt: Text(selectedProvider.apiKeyPlaceholder).foregroundColor(textTertiary))
                                            }
                                        }
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(textPrimary)

                                        Button {
                                            showApiKey[selectedProvider] = !(showApiKey[selectedProvider] ?? false)
                                        } label: {
                                            Image(systemName: (showApiKey[selectedProvider] ?? false) ? "eye.slash" : "eye")
                                                .font(.system(size: 11))
                                                .foregroundColor(textTertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(cardBorder, lineWidth: 1)
                                            )
                                    )
                                }

                                HStack(spacing: 12) {
                                    Button {
                                        saveApiKey(for: selectedProvider)
                                    } label: {
                                        HStack(spacing: 4) {
                                            if saveStatus[selectedProvider] == .saved {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            Text(statusText(for: selectedProvider))
                                        }
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(saveStatus[selectedProvider] == .saved ? Color.green : accent)
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        clearApiKey(for: selectedProvider)
                                    } label: {
                                        Text("Clear")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    Button {
                                        NSWorkspace.shared.open(selectedProvider.apiKeyHelpURL)
                                    } label: {
                                        HStack(spacing: 3) {
                                            Text("Get Key")
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider().background(cardBorder)

                            // Model Selection
                            HStack {
                                Text("Model")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(textSecondary)

                                Spacer()

                                Picker("", selection: $selectedModel) {
                                    ForEach(selectedProvider.availableModels, id: \.self) { model in
                                        Text(model)
                                            .font(.system(size: 11, design: .monospaced))
                                            .tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .onChange(of: selectedModel) { _, newValue in
                                    UserPreferences.shared.selectedModel = newValue
                                }
                            }
                        }
                    }

                    // Permissions Card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardHeader(icon: "lock.shield", title: "Permissions")

                            permissionRow(
                                icon: "keyboard.fill",
                                title: "Accessibility",
                                subtitle: "Hotkey & typing",
                                isGranted: PermissionsManager.shared.checkAccessibilityPermission()
                            )

                            permissionRow(
                                icon: "mic.fill",
                                title: "Microphone",
                                subtitle: "Voice recording",
                                isGranted: PermissionsManager.shared.checkMicrophonePermission()
                            )

                            Button {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 10))
                                    Text("Open System Settings")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // General Card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 14) {
                            cardHeader(icon: "gearshape", title: "General")

                            // Coding Mode
                            Toggle(isOn: $isCodingMode) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Coding Mode")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(textPrimary)
                                    Text("Use a more relaxed tone for dictation")
                                        .font(.system(size: 10))
                                        .foregroundColor(textTertiary)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(accent)
                            .onChange(of: isCodingMode) { _, newValue in
                                UserPreferences.shared.isCodingMode = newValue
                            }

                            if isCodingMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Custom Instructions")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(textSecondary)
                                    
                                    TextEditor(text: $codingModeInstructions)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(textPrimary)
                                        .frame(height: 80)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(cardBorder, lineWidth: 1)
                                                )
                                        )
                                        .scrollContentBackground(.hidden)
                                        .onChange(of: codingModeInstructions) { _, newValue in
                                            UserPreferences.shared.codingModeInstructions = newValue
                                        }
                                }
                            }

                            Divider().background(cardBorder)

                            Button {
                                appState.relaunchOnboarding?()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Replay Onboarding")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(textPrimary)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Usage Card
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            cardHeader(icon: "lightbulb", title: "How to Use")

                            VStack(alignment: .leading, spacing: 8) {
                                usageStep(number: "1", text: "Hold Right Option key")
                                usageStep(number: "2", text: "Speak naturally")
                                usageStep(number: "3", text: "Release to transcribe")
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 420, height: 580)
        .onAppear { loadSettings() }
    }

    // MARK: - Components

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(appState.status.description)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(cardBg)
                .overlay(Capsule().stroke(cardBorder, lineWidth: 1))
        )
    }

    private var statusColor: Color {
        switch appState.status {
        case .idle, .done: return .green
        case .initializing, .recording, .processing: return accent
        case .error: return .red
        }
    }

    private var warningBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("No AI provider configured")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textPrimary)
                Text("Add an API key to enable text cleanup")
                    .font(.system(size: 10))
                    .foregroundColor(textTertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func settingsCard<Content: View>(id: String = "", @ViewBuilder content: () -> Content) -> some View {
        let isHovered = hoveredCard == id && !id.isEmpty
        return VStack(alignment: .leading) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHovered ? Color.white.opacity(0.12) : cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            if !id.isEmpty {
                hoveredCard = hovering ? id : nil
            }
        }
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

    private func providerTab(_ provider: AIProviderType) -> some View {
        let isSelected = selectedProvider == provider
        let isHovered = hoveredTab == provider
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedProvider = provider
                selectedModel = provider.defaultModel
                UserPreferences.shared.selectedProvider = provider
                UserPreferences.shared.selectedModel = selectedModel
            }
        } label: {
            HStack(spacing: 6) {
                Text(provider.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))

                if KeychainManager.shared.hasAPIKey(for: provider) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(isSelected ? textPrimary : (isHovered ? textSecondary : textTertiary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.08) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredTab = hovering ? provider : nil
        }
    }

    private func permissionRow(icon: String, title: String, subtitle: String, isGranted: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isGranted ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isGranted ? .green : textTertiary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textPrimary)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(textTertiary)
            }

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isGranted ? .green : Color.white.opacity(0.15))
        }
    }

    private func usageStep(number: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .frame(width: 18, height: 18)
                .background(Circle().fill(accent.opacity(0.15)))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(textSecondary)
        }
    }

    // MARK: - Helpers

    private func statusText(for provider: AIProviderType) -> String {
        switch saveStatus[provider] {
        case .saved: return "Saved"
        case .error: return "Error"
        default: return "Save"
        }
    }

    private func binding(for provider: AIProviderType) -> Binding<String> {
        Binding(
            get: { apiKeys[provider] ?? "" },
            set: { apiKeys[provider] = $0 }
        )
    }

    private func loadSettings() {
        selectedProvider = UserPreferences.shared.selectedProvider
        selectedModel = UserPreferences.shared.selectedModel
        isCodingMode = UserPreferences.shared.isCodingMode
        codingModeInstructions = UserPreferences.shared.codingModeInstructions

        for provider in AIProviderType.allCases {
            if let key = KeychainManager.shared.getAPIKey(for: provider) {
                apiKeys[provider] = key
            }
            showApiKey[provider] = false
            saveStatus[provider] = .idle
        }
    }

    private func saveApiKey(for provider: AIProviderType) {
        guard let key = apiKeys[provider], !key.isEmpty else {
            saveStatus[provider] = .error
            return
        }

        if KeychainManager.shared.saveAPIKey(key, for: provider) {
            saveStatus[provider] = .saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveStatus[provider] = .idle
            }
        } else {
            saveStatus[provider] = .error
        }
    }

    private func clearApiKey(for provider: AIProviderType) {
        KeychainManager.shared.deleteAPIKey(for: provider)
        apiKeys[provider] = ""
        saveStatus[provider] = .idle
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
        }
    }
}
