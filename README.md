# Swiftly (macOS)
<img src="https://github.com/luanmdang/swiftly/blob/main/swiftly%20ex%201.gif" width="500" alt="Alt text"/>

---

## What is Swiftly?

Swiftly lives in your menu bar. You **press and hold a key**, speak naturally, then **release**, and your words appear in the currently focused app.

A small indicator near the top of your screen shows when Swiftly is listening.

**Privacy-first by default:** transcription happens on your Mac. No audio is sent to the internet **unless you choose** to enable optional “cleaner text” using your own API key.

---

## How it works (the user flow)

1. **Hold the key** — Press and hold **Right Option** (or **Right Command**) to start recording.
2. **Speak** — Say what you want typed. The on-screen indicator confirms Swiftly is listening.
3. **Release** — Let go of the key. Swiftly transcribes and types the result into the active app.

No app switching, no copy/paste, no “dictation mode.” Just speak where you’re already working.

<img src="https://github.com/luanmdang/swiftly/blob/main/swiftly%20onboarding%20screen.png" width="500" alt="Alt text"/>

---

## Under the hood (the pipeline)

Swiftly follows a simple chain:

**Voice → Whisper transcription → (optional) quick LLM rewrite → typed output**

- **Raw transcription:** Swiftly runs the **Whisper** model locally to convert audio into text.
- **Optional cleanup (recommended):** if you add an API key, Swiftly sends *only the text* (not audio) to a fast LLM to:
  - remove filler (“um”, “uh”)
  - fix punctuation + casing
  - reword for clarity while keeping meaning
- **Typing into the active app:** Swiftly then “types” the final text into whatever has focus using macOS Accessibility.

If you don’t enable cleanup, Swiftly simply types the raw transcription.

---

## Requirements

- **Mac** running macOS 14 (Sonoma) or later (Apple Silicon or Intel).
- **Permissions (required):**
  - **Accessibility** — so the hotkey + typing works
  - **Microphone** — so Swiftly can record audio

---

## Getting started

1. **Install**
   - Download the latest release from the Releases page:
     https://github.com/luanmdang/swiftly/releases
   - Or open the project in Xcode and run it (**Product → Run**).

2. **First launch**
   - Swiftly appears as a menu bar icon.
   - When macOS prompts for permissions, click **Open System Settings** and enable:
     - **Privacy & Security → Accessibility**
     - **Privacy & Security → Microphone**
   - If you’re running from Xcode, grant permissions to **Xcode** instead.

3. **Try it**
   - Click into any text field (Notes, Mail, Messages, etc.)
   - Hold **Right Option**, say a sentence, release
   - Your text should appear instantly

**API keys are never stored in the repo.** If you add a key, it’s saved only in your Mac’s **Keychain**.

---

## Optional: Cleaner text with an API key

By default, Swiftly types exactly what Whisper transcribes.

If you add an API key, Swiftly can “polish” your text: remove filler, fix punctuation, and reword for clarity—without changing meaning.

- Get a key (Gemini):
  https://aistudio.google.com/app/apikey
- Add it in Swiftly:
  **Menu bar icon → Settings → paste key → Save**

You can also use other providers (e.g., OpenAI, Claude) if you prefer.

**What I use:** Gemini 2.5 Flash Lite — fast + cheap.

---

## Troubleshooting

- **The hotkey does nothing**
  - Swiftly needs **Accessibility** permission.
  - Check: **System Settings → Privacy & Security → Accessibility**
  - Ensure **Swiftly** (or **Xcode** if running from Xcode) is enabled.
  - If it’s already enabled: toggle it off/on, then quit and reopen Swiftly.

- **Nothing is typed / microphone doesn’t work**
  - Check: **System Settings → Privacy & Security → Microphone**
  - Ensure Swiftly (or Xcode) is allowed.
  - Restart the app after changing the setting.

- **Something else?**
  - Open an issue on GitHub and include what you expected vs what happened:
    https://github.com/luanmdang/swiftly/issues

---

Disclaimer: The cute emoji logo is not mine

## License

This project is open source. See the repository for license terms.
If a `LICENSE` file is included, that file applies.
