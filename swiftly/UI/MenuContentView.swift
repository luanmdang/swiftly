import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject var appState: AppState
    let onSettings: () -> Void
    let onCheckPermissions: () -> Void
    let onQuit: () -> Void

    private var stats: UserPreferences { UserPreferences.shared }

    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            statsHeader
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 12)

            // Status Row
            statusRow
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 12)

            // Actions
            VStack(spacing: 2) {
                MenuActionRow(
                    icon: "gearshape.fill",
                    title: "Settings",
                    shortcut: "⌘,",
                    action: onSettings
                )

                MenuActionRow(
                    icon: "checkmark.shield.fill",
                    title: "Check Permissions",
                    action: onCheckPermissions
                )
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 12)

            // Quit
            MenuActionRow(
                icon: "power",
                title: "Quit Swiftly",
                shortcut: "⌘Q",
                isDestructive: true,
                action: onQuit
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .frame(width: 240)
        .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Main stats row
            HStack(spacing: 16) {
                StatPill(
                    value: formatNumber(stats.totalWords),
                    label: "words",
                    icon: "text.word.spacing"
                )

                StatPill(
                    value: "\(stats.totalTranscriptions)",
                    label: "clips",
                    icon: "waveform"
                )

                Spacer()

                // Time saved badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green.opacity(0.8))
                    Text(formattedTimeSaved)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.green.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            }

            // Session indicator (if active)
            if appState.sessionTranscriptions > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                    Text("Session: \(appState.sessionWords) words")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: 10) {
            // Status indicator dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.5), radius: 4)

            Text(appState.status.description)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Provider badge
            if KeychainManager.shared.hasAnyAPIKey() {
                Text(UserPreferences.shared.selectedProvider.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    private var statusColor: Color {
        switch appState.status {
        case .idle, .done: return .green
        case .initializing: return .orange
        case .recording: return .red
        case .processing: return .blue
        case .error: return .red
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fk", Double(number) / 1_000)
        }
        return "\(number)"
    }

    private var formattedTimeSaved: String {
        let averageWPM = 40.0
        let totalWords = Double(stats.totalWords)
        let minutesSaved = totalWords / averageWPM
        let hours = minutesSaved / 60.0

        if hours < 1 {
            let mins = Int(minutesSaved)
            return mins > 0 ? "\(mins)m" : "0m"
        } else {
            return String(format: "%.1fh", hours)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }
}

// MARK: - Menu Action Row

struct MenuActionRow: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDestructive ? .red.opacity(0.8) : .secondary)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isDestructive ? .red.opacity(0.9) : .primary)

                Spacer()

                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// VisualEffectBlur is now defined in SharedComponents.swift
