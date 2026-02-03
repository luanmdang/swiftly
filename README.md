# Swiftly (macOS)

Dictate with your voice and have it typed anywhere on your Mac.

## What is Swiftly?

Swiftly is a menu bar app for your Mac. You press and hold a key, speak, then release—and your words are typed into whatever app is in focus (email, notes, Slack, code, anywhere). A small indicator near the top of your screen shows when it’s recording. Your words are transcribed on your Mac; no audio is sent to the internet unless you choose to add an optional API key for cleaner text.

## How it works

1. **Hold the key.** Press and hold **Right Option** (or **Right Command**) to start recording.
2. **Speak.** Say what you want typed. A small bar at the top of your screen shows that Swiftly is listening.
3. **Release.** Let go of the key. Swiftly turns your speech into text and types it into the active app.

That’s it. No need to switch apps or paste—just talk and it appears where your cursor is.

## Requirements

- **Mac** with macOS 14 (Sonoma) or later (Apple Silicon or Intel).
- **Permissions:** Swiftly will ask for **Accessibility** (so the hotkey and typing work) and **Microphone** (so it can hear you). Both are required for the app to work.

## Getting started

1. **Download** the latest release from the [Releases](https://github.com/luanmdang/swiftly/releases) page, or open the project in Xcode and run it (Product → Run).
2. **First launch:** Swiftly appears as an icon in your menu bar. If you see an onboarding flow, follow the steps. When macOS asks for Accessibility and Microphone access, click **Open System Settings** and turn them on for Swiftly (or for Xcode if you’re running from Xcode).
3. **Try it:** Click in any text field (Notes, Mail, Messages, etc.), hold **Right Option**, say a sentence, then release. The text should appear.

Your API keys are never stored in the app’s code—only in your Mac’s Keychain, and only if you add them yourself.

## Optional: Cleaner text with an API key

Out of the box, Swiftly types what you say. If you add a free **API key** (for example from Google’s Gemini), Swiftly can tidy up your words: remove filler like “um” and “uh,” fix punctuation, and keep the meaning the same. This step is **optional**; the app works great without it.

- **Get a free key:** [Google AI Studio](https://aistudio.google.com/app/apikey) (Gemini).  
- **Add it in Swiftly:** Click the menu bar icon → **Settings** → enter your key and save. You can also add keys for other providers (e.g. OpenAI, Claude) if you use them.

I use Gemini 2.5 Flash Lite! Fast and cheap.

## Troubleshooting

- **The hotkey does nothing.**  
  Swiftly needs **Accessibility** permission. Open **System Settings → Privacy & Security → Accessibility** and ensure **Swiftly** (or **Xcode** if you’re running from Xcode) is listed and enabled. If it’s already on, turn it off and on again, then quit and reopen Swiftly.

- **Nothing is typed / microphone doesn’t work.**  
  Check **System Settings → Privacy & Security → Microphone** and ensure Swiftly (or Xcode) is allowed. Restart the app after changing this.

- **Something else?**  
  Open an [issue](https://github.com/luanmdang/swiftly/issues) on GitHub and describe what you see. We’re happy to help.

## License

This project is open source. See the repository for license terms. If a `LICENSE` file is included, that file applies.
