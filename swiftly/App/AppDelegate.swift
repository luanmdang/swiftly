import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var appState = AppState()
    var floatingPanel: FloatingPanel!
    var hotkeyManager: HotkeyManager!
    var audioRecorder: AudioRecorder!
    var transcriber: Transcriber!
    var keyboardOutput: KeyboardOutput!

    private var isRecording = false
    private var savedFrontmostApp: NSRunningApplication?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupFloatingPanel()
        setupComponents()

        appState.relaunchOnboarding = { [weak self] in
            self?.showOnboarding()
        }

        if !UserPreferences.shared.hasCompletedOnboarding {
            showOnboarding()
        } else {
            checkPermissions()
            initializeWhisperKit()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let icon = NSImage(named: "swiftly_squiggle") {
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Dictation")
            }
        }

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "Status: Initializing...", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 100
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check Permissions", action: #selector(checkAndRequestPermissions), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu

        appState.onStatusChange = { [weak self] status in
            DispatchQueue.main.async {
                if let menuItem = self?.statusItem.menu?.item(withTag: 100) {
                    menuItem.title = "Status: \(status.description)"
                }
            }
        }
    }

    private func setupFloatingPanel() {
        floatingPanel = FloatingPanel()

        let hostingView = NSHostingView(rootView: StatusIndicatorView().environmentObject(appState))
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: 32)

        floatingPanel.contentView = hostingView
        floatingPanel.setContentSize(NSSize(width: 280, height: 32))
    }

    private func setupComponents() {
        audioRecorder = AudioRecorder()
        keyboardOutput = KeyboardOutput()

        hotkeyManager = HotkeyManager { [weak self] isPressed in
            self?.handleHotkey(isPressed: isPressed)
        }
    }

    private func checkPermissions() {
        let permissions = PermissionsManager.shared

        if !permissions.checkAccessibilityPermission() {
            permissions.requestAccessibilityPermission()
        }

        permissions.requestMicrophonePermission { granted in
            if !granted {
                print("Microphone permission denied")
            }
        }
    }

    private func showOnboarding() {
        appState.isOnboarding = true

        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.completeOnboarding()
        }).environmentObject(appState)

        let hostingView = NSHostingView(rootView: onboardingView)

        onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        onboardingWindow?.title = "Welcome to Swiftly"
        onboardingWindow?.titlebarAppearsTransparent = true
        onboardingWindow?.titleVisibility = .hidden
        onboardingWindow?.isMovableByWindowBackground = true
        onboardingWindow?.contentView = hostingView
        onboardingWindow?.center()
        onboardingWindow?.isReleasedWhenClosed = false
        onboardingWindow?.backgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)

        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    private func completeOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
        appState.isOnboarding = false

        checkPermissions()
        initializeWhisperKit()
    }

    private func initializeWhisperKit() {
        appState.status = .initializing

        Task {
            do {
                transcriber = try await Transcriber()
                await MainActor.run {
                    appState.status = .idle
                    hotkeyManager.start()
                }
            } catch {
                await MainActor.run {
                    appState.status = .error("Failed to initialize WhisperKit: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleHotkey(isPressed: Bool) {
        if isPressed && !isRecording {
            startRecording()
        } else if !isPressed && isRecording {
            stopRecordingAndProcess()
        }
    }

    private func startRecording() {
        print("[Notch UI] startRecording called, current status=\(appState.status)")
        guard appState.status == .idle else {
            print("[Notch UI] startRecording: Not idle, ignoring. Status=\(appState.status)")
            return
        }

        isRecording = true
        savedFrontmostApp = NSWorkspace.shared.frontmostApplication

        appState.status = .recording
        showPanel()

        do {
            try audioRecorder.startRecording()
        } catch {
            appState.status = .error("Recording failed: \(error.localizedDescription)")
            isRecording = false
        }
    }

    private func stopRecordingAndProcess() {
        guard isRecording else { return }
        isRecording = false

        appState.status = .processing

        let audioData = audioRecorder.stopRecording()

        Task {
            do {
                print("[Notch UI] Starting WhisperKit transcription...")
                let rawText = try await transcriber.transcribe(audioData: audioData)
                print("[Notch UI] WhisperKit transcription result: \"\(rawText)\"")

                guard !rawText.isEmpty else {
                    print("[Notch UI] Transcription empty, returning to idle")
                    await MainActor.run {
                        appState.status = .idle
                        hidePanel()
                    }
                    return
                }

                // Clean text with AI provider if configured
                let cleanedText: String
                if ProviderManager.shared.hasAPIKeyConfigured {
                    do {
                        print("[Notch UI] Calling AI provider to clean text...")
                        cleanedText = try await ProviderManager.shared.clean(text: rawText)
                        print("[Notch UI] AI provider success, cleaned text length: \(cleanedText.count)")
                    } catch {
                        print("[Notch UI] AI provider ERROR: \(error.localizedDescription)")
                        print("[Notch UI] Using raw transcription instead")
                        cleanedText = rawText
                    }
                } else {
                    print("[Notch UI] No API key configured, using raw transcription")
                    cleanedText = rawText
                }

                // Type the result
                await MainActor.run {
                    appState.status = .done

                    savedFrontmostApp?.activate()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        self?.keyboardOutput.type(text: cleanedText)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.hidePanel()
                            self?.appState.status = .idle
                        }
                    }
                }
            } catch {
                print("[Notch UI] Processing error: \(error.localizedDescription)")
                await MainActor.run {
                    appState.status = .error(error.localizedDescription)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.hidePanel()
                        self?.appState.status = .idle
                    }
                }
            }
        }
    }

    private func showPanel() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let panelSize = floatingPanel.frame.size

        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.maxY - panelSize.height

        floatingPanel.setFrameOrigin(NSPoint(x: x, y: y))

        floatingPanel.alphaValue = 0
        floatingPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            floatingPanel.animator().alphaValue = 1
        })
    }

    private func hidePanel() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            floatingPanel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.floatingPanel.orderOut(nil)
            self?.floatingPanel.alphaValue = 1
        })
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView().environmentObject(appState)
        let hostingView = NSHostingView(rootView: settingsView)

        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.title = "Swiftly Settings"
        settingsWindow?.contentView = hostingView
        settingsWindow?.center()
        settingsWindow?.isReleasedWhenClosed = false

        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func checkAndRequestPermissions() {
        let permissions = PermissionsManager.shared

        if !permissions.checkAccessibilityPermission() {
            permissions.requestAccessibilityPermission()
        }

        permissions.requestMicrophonePermission { granted in
            print("Microphone permission: \(granted ? "granted" : "denied")")
        }
    }

    @objc private func quitApp() {
        hotkeyManager.stop()
        NSApp.terminate(nil)
    }
}
