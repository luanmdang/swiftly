import Cocoa

class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 32),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel behavior
        isFloatingPanel = true
        level = .screenSaver  // Higher level to ensure visibility above everything
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false  // No shadow - blends with notch

        // Don't take focus from other apps
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false

        // Ignore mouse events so clicks pass through
        ignoresMouseEvents = true
    }

    // Allow panel to receive mouse events without becoming key
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
