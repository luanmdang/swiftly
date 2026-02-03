import Cocoa
import Carbon

class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let callback: (Bool) -> Void
    private var isRightOptionPressed = false

    // Right Option key code
    private let rightOptionKeyCode: CGKeyCode = 61

    init(callback: @escaping (Bool) -> Void) {
        self.callback = callback
    }

    func start() {
        guard eventTap == nil else { return }
        
        // Check accessibility permission first
        let trusted = AXIsProcessTrusted()
        print("[Hotkey] AXIsProcessTrusted = \(trusted)")
        
        if !trusted {
            print("[Hotkey] ⚠️ Accessibility permission NOT granted!")
            print("[Hotkey] Opening System Settings to request permission...")
            
            // Prompt for permission with dialog
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            // Retry after a delay to allow user to grant permission
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                print("[Hotkey] Retrying after permission prompt...")
                self?.start()
            }
            return
        }

        // Listen for both flagsChanged (modifier keys) AND keyDown/keyUp for F18/F19 fallback
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue)

        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[Hotkey] Failed to create event tap even though AXIsProcessTrusted=true")
            print("[Hotkey] This might be a sandboxing or code signing issue")
            return
        }

        eventTap = tap

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("Hotkey manager started - listening for Right Option key")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil

        print("Hotkey manager stopped")
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Debug: log all key events to see what's coming through
        if type == .keyDown {
            print("[Hotkey] keyDown: keyCode=\(keyCode)")
        }
        
        if type == .flagsChanged {
            let flags = event.flags
            print("[Hotkey] flagsChanged: keyCode=\(keyCode), flags=\(flags.rawValue)")

            // Check if this is the Right Option key (key code 61)
            if keyCode == rightOptionKeyCode {
                // Check if Right Option is currently pressed
                let isPressed = flags.contains(.maskAlternate)

                if isPressed && !isRightOptionPressed {
                    print("[Hotkey] ▶️ Right Option PRESSED - starting recording")
                    isRightOptionPressed = true
                    DispatchQueue.main.async {
                        self.callback(true)
                    }
                } else if !isPressed && isRightOptionPressed {
                    print("[Hotkey] ⏹️ Right Option RELEASED - stopping recording")
                    isRightOptionPressed = false
                    DispatchQueue.main.async {
                        self.callback(false)
                    }
                }
            }
            
            // ALTERNATIVE: Also support Right Command key (key code 54) for testing
            let rightCommandKeyCode: CGKeyCode = 54
            if keyCode == Int64(rightCommandKeyCode) {
                let isPressed = flags.contains(.maskCommand)
                
                if isPressed && !isRightOptionPressed {
                    print("[Hotkey] ▶️ Right Command PRESSED - starting recording")
                    isRightOptionPressed = true
                    DispatchQueue.main.async {
                        self.callback(true)
                    }
                } else if !isPressed && isRightOptionPressed {
                    print("[Hotkey] ⏹️ Right Command RELEASED - stopping recording")
                    isRightOptionPressed = false
                    DispatchQueue.main.async {
                        self.callback(false)
                    }
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    deinit {
        stop()
    }
}
