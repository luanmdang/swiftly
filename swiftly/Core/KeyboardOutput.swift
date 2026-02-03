import Cocoa
import Carbon

class KeyboardOutput {
    func type(text: String) {
        // Use CGEvent to type each character
        for char in text {
            typeCharacter(char)
            // Small delay between characters for reliability
            usleep(5000) // 5ms
        }
    }

    private func typeCharacter(_ char: Character) {
        let string = String(char)

        // Create a key down event with the Unicode character
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // Use Unicode string input
        var unicodeChars = [UniChar]()
        for scalar in string.utf16 {
            unicodeChars.append(scalar)
        }

        // Create key down event
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            keyDown.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: unicodeChars)
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Create key up event
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
            keyUp.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: unicodeChars)
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
